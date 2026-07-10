import Foundation

@MainActor
final class AnalyzeViewModel: ObservableObject {
    @Published var stage: AnalysisStage = .transcribing
    @Published var detail: String?
    @Published var isRunning = false
    @Published var errorMessage: String?
    @Published var result: AnalysisResponse?
    @Published var requiresLogin = false
    @Published var requiresEmailVerification = false
    @Published var pipelineStages: [PipelineStageItem] = []
    @Published var researchProgress: String?
    @Published var progressTick = Date()

    private var progressTimer: Timer?
    private var activeEndpoint: AnalyzeEndpoint = .article
    private var analysisTask: Task<Void, Never>?
    private var analysisGeneration = 0
    private var wasCancelled = false

    func analyze(url: String, endpoint: AnalyzeEndpoint, authManager: AuthManager) async {
        analysisTask?.cancel()
        wasCancelled = false
        analysisGeneration += 1
        let generation = analysisGeneration

        let task = Task { @MainActor in
            await runAnalysis(url: url, endpoint: endpoint, authManager: authManager, generation: generation)
        }
        analysisTask = task
        await task.value
        if analysisGeneration == generation {
            analysisTask = nil
        }
    }

    func cancel() {
        guard isRunning else { return }
        wasCancelled = true
        analysisGeneration += 1
        analysisTask?.cancel()
        analysisTask = nil
        stopProgressTimer()
        markActiveStageError()
        isRunning = false
        errorMessage = Loc.t(.errAnalysisCancelled)
        result = nil
        AnalysisLiveActivityController.endAll()
        Haptics.selection()
    }

    private func runAnalysis(url: String, endpoint: AnalyzeEndpoint, authManager: AuthManager, generation: Int) async {
        isRunning = true
        errorMessage = nil
        requiresLogin = false
        requiresEmailVerification = false
        result = nil
        stage = endpoint == .article ? .scraping : .transcribing
        detail = nil
        researchProgress = nil
        activeEndpoint = endpoint
        setupPipeline(for: endpoint)
        startProgressTimer()
        AnalysisLiveActivityController.start(url: url, endpoint: endpoint)

        do {
            try Task.checkCancellation()
            try await performAnalysis(url: url, endpoint: endpoint, authManager: authManager, retryOnAuthError: true)
            if result != nil {
                AnalysisLiveActivityController.complete(url: url, success: true, message: Loc.t(.liveActivityDone))
            }
        } catch is CancellationError {
            if !wasCancelled {
                markActiveStageError()
                errorMessage = Loc.t(.errAnalysisCancelled)
            }
            AnalysisLiveActivityController.endMatching(url: url)
        } catch let apiError as APIError {
            guard !Task.isCancelled, !wasCancelled else { return }
            markActiveStageError()
            handleAPIError(apiError, authManager: authManager)
            AnalysisLiveActivityController.complete(url: url, success: false, message: Loc.t(.liveActivityFailed))
        } catch is DecodingError {
            guard !Task.isCancelled, !wasCancelled else { return }
            markActiveStageError()
            errorMessage = Loc.t(.errUnexpectedResponse)
            AnalysisLiveActivityController.complete(url: url, success: false, message: Loc.t(.liveActivityFailed))
        } catch let urlError as URLError {
            guard !Task.isCancelled, !wasCancelled else { return }
            markActiveStageError()
            if urlError.code == .cancelled {
                errorMessage = Loc.t(.errAnalysisCancelled)
                AnalysisLiveActivityController.endMatching(url: url)
            } else {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    OfflineAnalysisQueue.enqueue(url)
                    errorMessage = Loc.t(.networkOfflineQueued)
                case .timedOut:
                    errorMessage = Loc.t(.errTimeout)
                default:
                    errorMessage = Loc.t(.errNetwork)
                }
                AnalysisLiveActivityController.complete(url: url, success: false, message: Loc.t(.liveActivityFailed))
            }
        } catch {
            guard !Task.isCancelled, !wasCancelled else { return }
            markActiveStageError()
            errorMessage = error.localizedDescription
            AnalysisLiveActivityController.complete(url: url, success: false, message: Loc.t(.liveActivityFailed))
        }

        stopProgressTimer()
        if !wasCancelled && analysisGeneration == generation {
            isRunning = false
        }
    }

    private func performAnalysis(
        url: String,
        endpoint: AnalyzeEndpoint,
        authManager: AuthManager,
        retryOnAuthError: Bool
    ) async throws {
        try Task.checkCancellation()
        let idToken = try await authManager.getIDToken(forceRefresh: false)
        let model: String? = endpoint == .article ? APIConfig.articleModel : nil

        markPipeline(.pow, status: .active)
        let pow = try await APIClient.shared.solveChallenge()
        try Task.checkCancellation()
        markPipeline(.pow, status: .done)

        let firstStage: PipelineStageId = endpoint == .article ? .scraping : .transcribing
        markPipeline(firstStage, status: .active)

        do {
            let data = try await APIClient.shared.analyze(
                path: endpoint.path,
                url: url,
                lang: Loc.code,
                model: model,
                idToken: idToken,
                pow: pow
            ) { [weak self] newStage, newDetail in
                Task { @MainActor in
                    guard let self, !self.wasCancelled else { return }
                    self.applyProgress(stage: newStage, detail: newDetail)
                    let done = Double(self.pipelineStages.filter { $0.status == .done }.count)
                    let total = max(Double(self.pipelineStages.count), 1)
                    let label: String = {
                        if let newDetail, !newDetail.isEmpty { return newDetail }
                        return self.detail ?? Loc.t(.liveActivityStarting)
                    }()
                    AnalysisLiveActivityController.update(
                        url: url,
                        stageLabel: label,
                        progress: min((done + 0.5) / total, 0.95)
                    )
                }
            }

            try Task.checkCancellation()
            completeAllStages()
            let decoded = try JSONDecoder().decode(AnalysisResponse.self, from: data)
            result = decoded
        } catch let apiError as APIError {
            // Only retry auth expiry (401). Quota (402) must not be retried.
            if retryOnAuthError,
               apiError.status == 401,
               authManager.isLoggedIn,
               (try? await authManager.getIDToken(forceRefresh: true)) != nil {
                try Task.checkCancellation()
                try await performAnalysis(
                    url: url,
                    endpoint: endpoint,
                    authManager: authManager,
                    retryOnAuthError: false
                )
                return
            }
            throw apiError
        }
    }

    private func setupPipeline(for endpoint: AnalyzeEndpoint) {
        pipelineStages = PipelineStageId.defaultPipeline(for: endpoint).map {
            PipelineStageItem(id: $0, status: .pending, startedAt: nil, finishedAt: nil)
        }
    }

    private func markPipeline(_ id: PipelineStageId, status: PipelineStageStatus) {
        let now = Date()
        for index in pipelineStages.indices where pipelineStages[index].id == id {
            pipelineStages[index].status = status
            if status == .active, pipelineStages[index].startedAt == nil {
                pipelineStages[index].startedAt = now
            }
            if status == .done || status == .error {
                pipelineStages[index].finishedAt = now
            }
        }
    }

    private func applyProgress(stage newStage: AnalysisStage, detail newDetail: String?) {
        stage = newStage
        detail = newDetail
        if newStage == .researching, let newDetail, !newDetail.isEmpty {
            researchProgress = newDetail
        }
        PipelineStageTracker.applyProgress(stage: newStage, endpoint: activeEndpoint, stages: &pipelineStages)
    }

    private func completeAllStages() {
        let now = Date()
        for index in pipelineStages.indices {
            if pipelineStages[index].status != .error {
                pipelineStages[index].status = .done
                pipelineStages[index].finishedAt = pipelineStages[index].finishedAt ?? now
            }
        }
    }

    private func markActiveStageError() {
        for index in pipelineStages.indices where pipelineStages[index].status == .active {
            pipelineStages[index].status = .error
            pipelineStages[index].finishedAt = Date()
        }
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.progressTick = Date() }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func handleAPIError(_ error: APIError, authManager: AuthManager) {
        if error.status == 402 {
            requiresLogin = true
            errorMessage = authManager.isLoggedIn ? Loc.t(.quotaSoftWallMessage) : Loc.t(.errGuestQuota)
            return
        }
        if error.status == 401 {
            requiresLogin = !authManager.isLoggedIn
        } else if error.status == 403,
                  error.message.lowercased().contains("verify") || error.message.lowercased().contains("email") {
            requiresEmailVerification = true
        }
        errorMessage = APIErrorMapper.message(for: error)
    }

    /// Simulates a full article pipeline using bundled data — no API call, no token usage.
    func runDemoAnalysis() async {
        isRunning = true
        errorMessage = nil
        requiresLogin = false
        requiresEmailVerification = false
        result = nil
        activeEndpoint = .article
        stage = .scraping
        detail = nil
        researchProgress = nil
        wasCancelled = false
        setupPipeline(for: .article)
        startProgressTimer()

        let steps: [(PipelineStageId, AnalysisStage, UInt64, String?)] = [
            (.scraping, .scraping, 900_000_000, Loc.t(.postLoginDemoStageScrape)),
            (.analyzing, .analyzing, 1_400_000_000, Loc.t(.postLoginDemoStageAnalyze)),
            (.judging, .judging, 1_100_000_000, Loc.t(.postLoginDemoStageVerdict))
        ]

        for (pipelineId, analysisStage, delay, stepDetail) in steps {
            if Task.isCancelled || wasCancelled { break }
            markPipeline(pipelineId, status: .active)
            stage = analysisStage
            detail = stepDetail
            try? await Task.sleep(nanoseconds: delay)
            markPipeline(pipelineId, status: .done)
        }

        if !wasCancelled && !Task.isCancelled {
            completeAllStages()
            result = DemoAnalysisProvider.makeResponse()
        }
        stopProgressTimer()
        isRunning = false
    }

    func reset() {
        analysisTask?.cancel()
        analysisTask = nil
        analysisGeneration += 1
        wasCancelled = false
        stopProgressTimer()
        stage = .transcribing
        detail = nil
        isRunning = false
        errorMessage = nil
        result = nil
        requiresLogin = false
        requiresEmailVerification = false
        pipelineStages = []
        researchProgress = nil
    }
}
