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

    func analyze(url: String, endpoint: AnalyzeEndpoint, authManager: AuthManager) async {
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

        do {
            let idToken = try await authManager.getIDToken()
            let model: String? = endpoint == .article ? APIConfig.articleModel : nil

            markPipeline(.pow, status: .active)
            let pow = try await APIClient.shared.solveChallenge()
            markPipeline(.pow, status: .done)

            let firstStage: PipelineStageId = endpoint == .article ? .scraping : .transcribing
            markPipeline(firstStage, status: .active)

            let data = try await APIClient.shared.analyze(
                path: endpoint.path,
                url: url,
                lang: Loc.code,
                model: model,
                idToken: idToken,
                pow: pow
            ) { [weak self] newStage, newDetail in
                Task { @MainActor in
                    self?.applyProgress(stage: newStage, detail: newDetail)
                }
            }

            completeAllStages()
            let decoded = try JSONDecoder().decode(AnalysisResponse.self, from: data)
            result = decoded
        } catch let apiError as APIError {
            markActiveStageError()
            handleAPIError(apiError)
        } catch is DecodingError {
            markActiveStageError()
            errorMessage = Loc.t(.errUnexpectedResponse)
        } catch let urlError as URLError {
            markActiveStageError()
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                errorMessage = Loc.t(.errNoInternet)
            case .timedOut:
                errorMessage = Loc.t(.errTimeout)
            default:
                errorMessage = Loc.t(.errNetwork)
            }
        } catch {
            markActiveStageError()
            errorMessage = error.localizedDescription
        }

        stopProgressTimer()
        isRunning = false
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

    private func handleAPIError(_ error: APIError) {
        if error.status == 401 || error.status == 402 {
            requiresLogin = true
        } else if error.status == 403,
                  error.message.lowercased().contains("verify") || error.message.lowercased().contains("email") {
            requiresEmailVerification = true
        }
        errorMessage = APIErrorMapper.message(for: error)
    }

    func reset() {
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
