// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Speech
import AVFoundation

/// A full-screen view controller that records audio, visualizes the voice waveform,
/// and transcribes speech to text. On completion the transcribed text is passed to
/// the `onSearchQuery` closure so the caller can perform a web search.
final class VoiceSearchViewController: UIViewController {

    // MARK: - UX Constants

    private enum UX {
        static let micButtonSize: CGFloat = 80
        static let waveformHeight: CGFloat = 120
        static let waveformBarCount: Int = 40
        static let waveformBarWidth: CGFloat = 3
        static let waveformBarSpacing: CGFloat = 2
        static let cornerRadius: CGFloat = 40
        static let backgroundColor = UIColor.black.withAlphaComponent(0.85)
        static let accentColor = UIColor.systemGreen
        static let cancelButtonTopPadding: CGFloat = 16
        static let transcriptTopPadding: CGFloat = 32
        static let micButtonBottomPadding: CGFloat = 60
        static let instructionBottomPadding: CGFloat = 24
        static let animationDuration: TimeInterval = 0.15
        /// Delay before submitting the final transcript, giving the speech recognizer time
        /// to produce its best result after the user stops recording manually.
        static let finalTranscriptionDelay: TimeInterval = 1.0
        /// Multiplier applied to average audio amplitude to normalize it into a 0–1 range
        /// suitable for the waveform visualizer. Typical speech amplitudes average 0.01–0.1,
        /// so a 10× multiplier fills the visual range.
        static let audioLevelNormalizationMultiplier: Float = 10
    }

    // MARK: - Properties

    private let onSearchQuery: (String) -> Void

    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var isRecording = false

    // MARK: - UI Elements

    private let blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = .VoiceSearch.CancelButtonAccessibilityLabel
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        return button
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = .VoiceSearch.InstructionLabel
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let transcriptLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let micButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = UX.micButtonSize / 2
        button.backgroundColor = UX.accentColor
        button.accessibilityLabel = .VoiceSearch.MicButtonAccessibilityLabel
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let image = UIImage(systemName: "mic.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        return button
    }()

    private let waveformView: AudioWaveformView = {
        let view = AudioWaveformView(
            barCount: UX.waveformBarCount,
            barWidth: UX.waveformBarWidth,
            barSpacing: UX.waveformBarSpacing,
            barColor: UX.accentColor
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    init(onSearchQuery: @escaping (String) -> Void) {
        self.onSearchQuery = onSearchQuery
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestPermissionsAndStart()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRecording()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(blurView)
        view.addSubview(cancelButton)
        view.addSubview(transcriptLabel)
        view.addSubview(waveformView)
        view.addSubview(instructionLabel)
        view.addSubview(micButton)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                              constant: UX.cancelButtonTopPadding),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            transcriptLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            transcriptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            transcriptLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            waveformView.heightAnchor.constraint(equalToConstant: UX.waveformHeight),
            waveformView.bottomAnchor.constraint(equalTo: instructionLabel.topAnchor, constant: -16),

            instructionLabel.bottomAnchor.constraint(equalTo: micButton.topAnchor,
                                                     constant: -UX.instructionBottomPadding),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                              constant: -UX.micButtonBottomPadding),
            micButton.widthAnchor.constraint(equalToConstant: UX.micButtonSize),
            micButton.heightAnchor.constraint(equalToConstant: UX.micButtonSize),
        ])
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        stopRecording()
        dismiss(animated: true)
    }

    @objc private func micTapped() {
        if isRecording {
            finishRecording()
        } else {
            startRecording()
        }
    }

    // MARK: - Permissions

    private func requestPermissionsAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.requestMicrophoneAndStart()
                default:
                    self?.showPermissionDeniedAlert(for: .VoiceSearch.SpeechPermissionDeniedMessage)
                }
            }
        }
    }

    private func requestMicrophoneAndStart() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startRecording()
                } else {
                    self?.showPermissionDeniedAlert(for: .VoiceSearch.MicrophonePermissionDeniedMessage)
                }
            }
        }
    }

    private func showPermissionDeniedAlert(for message: String) {
        let alert = UIAlertController(
            title: .VoiceSearch.PermissionDeniedTitle,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: .VoiceSearch.OpenSettingsButton, style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: .VoiceSearch.CancelButton, style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Recording

    private func startRecording() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            showPermissionDeniedAlert(for: .VoiceSearch.SpeechUnavailableMessage)
            return
        }

        // Cancel any in-progress task
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.processAudioBuffer(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let transcript = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcriptLabel.text = transcript
                }

                if result.isFinal {
                    self.stopRecording()
                    DispatchQueue.main.async {
                        self.submitSearch(query: transcript)
                    }
                }
            }

            if error != nil {
                self.stopRecording()
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            return
        }

        isRecording = true
        updateUIForRecordingState()
    }

    private func stopRecording() {
        guard isRecording else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        isRecording = false
        DispatchQueue.main.async { [weak self] in
            self?.updateUIForRecordingState()
        }
    }

    private func finishRecording() {
        guard isRecording else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        // Let the recognition task produce its final result via the completion handler
        isRecording = false
        updateUIForRecordingState()

        // If we already have a transcript, submit it after a brief delay to allow final results
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.finalTranscriptionDelay) { [weak self] in
            guard let self else { return }
            if let text = self.transcriptLabel.text, !text.isEmpty, self.recognitionTask != nil {
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
                self.recognitionRequest = nil
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                self.submitSearch(query: text)
            }
        }
    }

    // MARK: - Audio Processing

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<frameCount {
            sum += abs(channelData[i])
        }
        let average = sum / Float(frameCount)
        let normalizedLevel = min(average * UX.audioLevelNormalizationMultiplier, 1.0)

        DispatchQueue.main.async { [weak self] in
            self?.waveformView.addLevel(CGFloat(normalizedLevel))
        }
    }

    // MARK: - UI State

    private func updateUIForRecordingState() {
        UIView.animate(withDuration: UX.animationDuration) { [self] in
            if isRecording {
                micButton.backgroundColor = .systemRed
                let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
                micButton.setImage(UIImage(systemName: "stop.fill", withConfiguration: config), for: .normal)
                instructionLabel.text = .VoiceSearch.ListeningLabel
                waveformView.alpha = 1
            } else {
                micButton.backgroundColor = UX.accentColor
                let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
                micButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)
                instructionLabel.text = .VoiceSearch.InstructionLabel
                waveformView.alpha = 0.3
                waveformView.reset()
            }
        }
    }

    // MARK: - Search Submission

    private func submitSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            dismiss(animated: true)
            return
        }
        dismiss(animated: true) { [weak self] in
            self?.onSearchQuery(trimmed)
        }
    }
}

// MARK: - Localized Strings

extension String {
    enum VoiceSearch {
        static let InstructionLabel = NSLocalizedString(
            "VoiceSearch.Instruction",
            tableName: "Ecosia",
            value: "Tap to speak",
            comment: "Instruction label on the voice search screen"
        )
        static let ListeningLabel = NSLocalizedString(
            "VoiceSearch.Listening",
            tableName: "Ecosia",
            value: "Listening…",
            comment: "Label shown while recording voice input"
        )
        static let PermissionDeniedTitle = NSLocalizedString(
            "VoiceSearch.PermissionDenied.Title",
            tableName: "Ecosia",
            value: "Permission Required",
            comment: "Title for the permission denied alert"
        )
        static let SpeechPermissionDeniedMessage = NSLocalizedString(
            "VoiceSearch.SpeechPermissionDenied.Message",
            tableName: "Ecosia",
            value: "Please allow speech recognition access in Settings to use voice search.",
            comment: "Message when speech recognition permission is denied"
        )
        static let MicrophonePermissionDeniedMessage = NSLocalizedString(
            "VoiceSearch.MicrophonePermissionDenied.Message",
            tableName: "Ecosia",
            value: "Please allow microphone access in Settings to use voice search.",
            comment: "Message when microphone permission is denied"
        )
        static let SpeechUnavailableMessage = NSLocalizedString(
            "VoiceSearch.SpeechUnavailable.Message",
            tableName: "Ecosia",
            value: "Speech recognition is not available on this device.",
            comment: "Message when speech recognition is unavailable"
        )
        static let OpenSettingsButton = NSLocalizedString(
            "VoiceSearch.OpenSettings",
            tableName: "Ecosia",
            value: "Open Settings",
            comment: "Button to open system settings for permissions"
        )
        static let CancelButton = NSLocalizedString(
            "VoiceSearch.Cancel",
            tableName: "Ecosia",
            value: "Cancel",
            comment: "Cancel button on the voice search permission alert"
        )
        static let CancelButtonAccessibilityLabel = NSLocalizedString(
            "VoiceSearch.CancelButton.AccessibilityLabel",
            tableName: "Ecosia",
            value: "Cancel voice search",
            comment: "Accessibility label for the cancel button"
        )
        static let MicButtonAccessibilityLabel = NSLocalizedString(
            "VoiceSearch.MicButton.AccessibilityLabel",
            tableName: "Ecosia",
            value: "Start voice search",
            comment: "Accessibility label for the microphone button"
        )
    }
}
