import AVFoundation
import SwiftUI

/// Camera session for barcode and QR. Stops when the scan sheet leaves or the app backgrounds.
final class BarcodeCapture: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "cms.barcode.capture")
    private var onPayload: (@Sendable (String) -> Void)?
    private var onFailure: (@Sendable (String) -> Void)?
    private var configured = false
    private var frame = 0
    private let lateFrames = LateFrameGate()

    func setHandlers(
        payload: @escaping @Sendable (String) -> Void,
        failure: @escaping @Sendable (String) -> Void
    ) {
        queue.async {
            self.onPayload = payload
            self.onFailure = failure
        }
    }

    func start() {
        queue.async {
            self.configureIfNeeded()
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        queue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }
        guard let device = AVCaptureDevice.default(for: .video) else {
            onFailure?("Scan failed. Try again.")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                onFailure?("Scan failed. Try again.")
                return
            }
            session.addInput(input)
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            onFailure?("Scan failed. Try again.")
            return
        }
        let metadata = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadata) else {
            onFailure?("Scan failed. Try again.")
            return
        }
        session.addOutput(metadata)
        metadata.setMetadataObjectsDelegate(self, queue: queue)
        let wanted: [AVMetadataObject.ObjectType] = [.qr, .ean13, .ean8, .upce]
        let supported = wanted.filter { metadata.availableMetadataObjectTypes.contains($0) }
        if !supported.isEmpty {
            metadata.metadataObjectTypes = supported
        }
        let video = AVCaptureVideoDataOutput()
        video.alwaysDiscardsLateVideoFrames = true
        video.setSampleBufferDelegate(lateFrames, queue: queue)
        if session.canAddOutput(video) {
            session.addOutput(video)
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        frame += 1
        if frame % 3 != 0 { return }
        guard let code = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first?.stringValue else {
            return
        }
        onPayload?(code)
    }
}

final class LateFrameGate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        _ = sampleBuffer
    }
}

struct AVCaptureMetadataOutputHost: View {
    var session: AVCaptureSession

    var body: some View {
        CameraPreview(session: session)
            .aspectRatio(0.8, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Chrome.card, style: .continuous))
            .overlay {
                ScanReticle()
                    .stroke(DesignTokens.ink)
                    .padding(Spacing.s6)
                    .accessibilityHidden(true)
            }
            .accessibilityLabel("Camera preview")
    }
}

struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewHost {
        let view = PreviewHost()
        view.attach(session)
        return view
    }

    func updateUIView(_ uiView: PreviewHost, context: Context) {
        uiView.attach(session)
    }
}

final class PreviewHost: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    func attach(_ session: AVCaptureSession) {
        guard let preview = layer as? AVCaptureVideoPreviewLayer else { return }
        preview.session = session
        preview.videoGravity = .resizeAspectFill
    }
}

struct ScanReticle: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(rect.width, rect.height) * 0.18
        var path = Path()
        let corners = [
            (rect.minX, rect.minY, 1.0, 1.0),
            (rect.maxX, rect.minY, -1.0, 1.0),
            (rect.minX, rect.maxY, 1.0, -1.0),
            (rect.maxX, rect.maxY, -1.0, -1.0)
        ]
        for corner in corners {
            path.move(to: CGPoint(x: corner.0, y: corner.1))
            path.addLine(to: CGPoint(x: corner.0 + length * corner.2, y: corner.1))
            path.move(to: CGPoint(x: corner.0, y: corner.1))
            path.addLine(to: CGPoint(x: corner.0, y: corner.1 + length * corner.3))
        }
        return path
    }
}

struct SimulatorSampleShelf: View {
    var onPick: (ShelfIdentity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "SAMPLE CODES")
            ForEach(LocalShelfCatalog.products) { item in
                Button {
                    onPick(item)
                } label: {
                    HStack(spacing: Spacing.s3) {
                        VStack(alignment: .leading, spacing: Spacing.s1) {
                            Text(item.title)
                                .font(TypeFace.body)
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text(item.brand)
                                .font(TypeFace.caption)
                                .foregroundStyle(DesignTokens.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: Spacing.s2)
                        Text(item.barcode)
                            .font(TypeFace.caption)
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    .padding(.horizontal, Spacing.s4)
                    .frame(maxWidth: .infinity, minHeight: Chrome.hit, alignment: .leading)
                    .paperPlate(chip: true)
                }
                .buttonStyle(CardPressStyle())
            }
        }
    }
}
