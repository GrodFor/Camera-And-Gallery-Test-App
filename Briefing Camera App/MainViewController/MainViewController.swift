//
//  MainViewController.swift
//  Briefing Camera App
//
//  Created by Vladislav Sitsko on 16.10.23.
//

import UIKit
import SnapKit
import AVFoundation
import CoreMotion

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private lazy var cameraButtton = UIButton()
    private lazy var galleryButton = UIButton()
    
    private lazy var captureSession = AVCaptureSession()
    private var backFacingCamera: AVCaptureDevice?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private var stillImageOutput: AVCapturePhotoOutput!
    private var stillImage: UIImage?
        
    private var lastKnownOrientation: AVCaptureVideoOrientation = .portrait
    private lazy var motionManager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(rotate),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                self?.requestPermission { [weak self] allowed in
                    guard allowed else { return }
                    DispatchQueue.main.async { [weak self] in
                        self?.configure()
                    }
                }
            case .authorized:
                DispatchQueue.main.async { [weak self] in
                    self?.configure()
                }
            case .denied, .restricted:
                print("not allowed")
            @unknown default:
                break
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkOrientation { [weak self] orientation in
            guard
                let self = self,
                let orientation = orientation,
                orientation != self.lastKnownOrientation
            else {
                return
            }
            
            self.lastKnownOrientation = orientation
            self.rotate()
        }
    }
    
    private func requestPermission(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(
            for: AVMediaType.video,
            completionHandler: { (allowedAccess) -> Void in
                completion(allowedAccess)
            }
        )
    }

    private func configure() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: .unspecified
        )
        
        backFacingCamera = deviceDiscoverySession.devices.first(where: { $0.position == .back })
        
        guard
            let backFacingCamera,
            let captureDeviceInput = try? AVCaptureDeviceInput(device: backFacingCamera)
        else {
            return
        }
        
        stillImageOutput = AVCapturePhotoOutput()
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(stillImageOutput)
        
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame
        
        view.bringSubviewToFront(cameraButtton)
        view.bringSubviewToFront(galleryButton)
                
        captureSession.startRunning()
    }
}

// MARK: - SetupViews

private extension MainViewController {
    func setupViews() {
        cameraButtton.setImage(UIImage(named: "cameraIcon"), for: .normal)
        cameraButtton.addTarget(self, action: #selector(cameraButttonPressed), for: .touchUpInside)
        view.addSubview(cameraButtton)
        
        galleryButton.setImage(UIImage(named: "galleryIcon"), for: .normal)
        galleryButton.addTarget(self, action: #selector(galleryButtonPressed), for: .touchUpInside)
        view.addSubview(galleryButton)
    }
}


// MARK: - SetupConstraints

private extension MainViewController {
    func setupConstraints() {
        cameraButtton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(120)
            make.bottom.equalToSuperview().inset(20)
        }
        
        galleryButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(70)
            make.width.equalTo(72)
        }
    }
}

// MARK: - Action

@objc private extension MainViewController {
    func cameraButttonPressed() {
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        
        stillImageOutput.isHighResolutionCaptureEnabled = true
        stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func galleryButtonPressed() {
        let viewController = GalleryViewController()
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }
    
    func rotate() {
        rotateVideoLayer()
        
        var angle: CGFloat = 0.0
        
        switch (self.lastKnownOrientation) {
        case .landscapeLeft:
            angle = CGFloat(-90.0 * .pi)/CGFloat(180.0)
        case .landscapeRight:
            angle = CGFloat(90.0 * .pi)/CGFloat(180.0)
        default:
            angle = 0.0
        }
                
        UIView.animate(withDuration: 0.25) {[weak self] in
            guard let self = self else { return }

            if !(angle == 0.0 && self.galleryButton.transform.isIdentity){
                self.galleryButton.transform = CGAffineTransform(rotationAngle: angle)
            }

            if !(angle == 0.0 && self.cameraButtton.transform.isIdentity){
                self.cameraButtton.transform = CGAffineTransform(rotationAngle: angle)
            }
        }
    }
    
    func rotateVideoLayer() {
        let newVideoOrientation: AVCaptureVideoOrientation
        
        if let orientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) {
            newVideoOrientation = orientation
        } else {
            newVideoOrientation = self.lastKnownOrientation
        }
        
        if let captureSessionConnection = captureSession.connections.first, captureSessionConnection.isVideoOrientationSupported {
            captureSessionConnection.videoOrientation = newVideoOrientation
        }
    }
}

extension MainViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil else {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        stillImage = UIImage(data: imageData)
        
        let alert = UIAlertController(title: "Save image to gallery?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        alert.addAction(
            UIAlertAction(
                title: "Yes",
                style: UIAlertAction.Style.default,
                handler: { [weak self] _ in
                    guard let stillImage = self?.stillImage else { return }
                    UIImageWriteToSavedPhotosAlbum(stillImage, nil, nil, nil)
                }
            )
        )
        
        present(alert, animated: true)
    }
}

extension MainViewController {
    private func checkOrientation(completion: @escaping(_ orientation: AVCaptureVideoOrientation?)->()) {
        motionManager.accelerometerUpdateInterval = 1.5
        motionManager.startAccelerometerUpdates( to: OperationQueue() ) { data, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            
            let orientation: AVCaptureVideoOrientation = abs(data.acceleration.y) < abs(data.acceleration.x)
                ? data.acceleration.x > 0 ? .landscapeLeft : .landscapeRight
                : data.acceleration.y > 0 ? .portraitUpsideDown : .portrait
            
            DispatchQueue.main.async {
                completion(orientation)
            }
        }
    }
}

