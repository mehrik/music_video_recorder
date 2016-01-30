//
//  CameraViewController.swift
//  music-video-recorder
//
//  Created by Maric Sobreo on 1/25/16.
//  Copyright © 2016 Maric Sobreo (Coding Dojo). All rights reserved.
//

import UIKit
import AVFoundation
// Used for saving?
import CoreImage
import Photos

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var bottomView: UIView!
    
    var recording = false
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraDevice: AVCaptureDevice?
    var cameraDeviceInput: AVCaptureDeviceInput?
    var movieOutput: AVCaptureMovieFileOutput?
    var outputURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let session = AVAudioSession.sharedInstance()
        // Allows sound from other apps to not be stopped
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
        
        PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
            switch status{
            case .Authorized:
                dispatch_async(dispatch_get_main_queue(), {
                    print("Authorized")
                })
                break
            case .Denied:
                dispatch_async(dispatch_get_main_queue(), {
                    print("Denied")
                })
                break
            default:
                dispatch_async(dispatch_get_main_queue(), {
                    print("Default")
                })
                break
            }
        })
        
        
        
        // MARK: Input -----------------------------------------------------
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPresetHigh
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraDevice = getCameraWithPosition(AVCaptureDevicePosition.Front)
        cameraDeviceInput = try! AVCaptureDeviceInput(device: cameraDevice!)
        
        NSLog("Other devices playing: %@", session.otherAudioPlaying)
        NSLog("Available inputs: %@", session.availableInputs!)
        NSLog("Input Data Sources: %@", session.inputDataSources!)
        NSLog("Inputs: %@", session.currentRoute.inputs)
        NSLog("Outputs: %@", session.currentRoute.outputs)
        
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let audioDeviceInput = try! AVCaptureDeviceInput(device: audioDevice!)
        
        // Capture session has cameraDevice as an input
        // Must input audio first so able to swap out the camera stuff for later
        // AVCapture input Microphone
        if ((captureSession?.canAddInput(audioDeviceInput)) != nil) {
            captureSession?.addInput(audioDeviceInput)
        }
        
        // AVCapture input Camera
        if ((captureSession?.canAddInput(cameraDeviceInput)) != nil) {
            captureSession?.addInput(cameraDeviceInput)
        }
        
        // MARK: Output
        movieOutput = AVCaptureMovieFileOutput()
        movieOutput?.movieFragmentInterval = kCMTimeInvalid
        if ((captureSession?.canAddOutput(movieOutput)) != nil) {
            captureSession?.addOutput(movieOutput)
        }
        
        // MARK: Preview Layer ---------------------------------------------
        previewLayer!.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResize
        
        // Orientation of previewLayer DOES NOT effect the encoding of the actual video file
        // Need to figure out how to save the video file rotated
        previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        view.layer.addSublayer(previewLayer!)
        
        // MARK: Add button and bottom view ontop
        makeButtonRoundAndAddToView(recordButton)
        view.addSubview(bottomView)
        
        captureSession?.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (!recording) {
            let session = AVAudioSession.sharedInstance()
            // Allows sound from other apps to not be stopped
            try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
            if ((captureSession) != nil) {
            captureSession?.beginConfiguration()
            let currentCameraInput = captureSession?.inputs[1] as! AVCaptureInput
            
            captureSession?.removeInput(currentCameraInput)
            
            if cameraDevice!.position == AVCaptureDevicePosition.Front {
                cameraDevice = getCameraWithPosition(AVCaptureDevicePosition.Back)
            } else {
                cameraDevice = getCameraWithPosition(AVCaptureDevicePosition.Front)
            }
            let newDeviceInput = try! AVCaptureDeviceInput(device: cameraDevice)
            captureSession?.addInput(newDeviceInput)
            print(captureSession?.inputs)
            
            captureSession?.commitConfiguration()
            }
        }
        
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    //
    // MARK: AVCaptureFileOutputRecordingDelegate Functions
    //
    //////////////////////////////////////////////////////////////////////////////////////////
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("Started recording")
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if let err = error {
            print(err)
        } else {
            print("MOVIE HAS FINISHED SAVING")
            // Save video to photolibrary
            // Clear out temporary directory
            let sharedPhotoLibrary = PHPhotoLibrary.sharedPhotoLibrary()
            sharedPhotoLibrary.performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(self.outputURL!)
                }, completionHandler: { success, error in
                    NSLog("Finished updating asset. %@", (success ? "Success." : error!))
                    self.clearTemporaryDirectory()
            })
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    //
    // MARK: Custom Functions
    //
    //////////////////////////////////////////////////////////////////////////////////////////
    func recordMovie() {
        outputURL = NSURL(fileURLWithPath: NSTemporaryDirectory() + "silentVideo.mp4")
        movieOutput?.startRecordingToOutputFileURL(outputURL, recordingDelegate: self)
    }
    
    func saveMovie() {
        movieOutput?.stopRecording()
        
    }
    
    func getCameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if device.position == position {
                return device as? AVCaptureDevice
            }
        }
        return nil
    }
    
    func makeButtonRoundAndAddToView(button: UIButton) {
        button.backgroundColor = UIColor.cyanColor()
        button.layer.cornerRadius = button.frame.size.width / 2
        button.clipsToBounds = true
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.layer.borderWidth = 3
    }
    
    func clearTemporaryDirectory() {
        print("Trying to clear temp direct")
        let fileManager = NSFileManager()
        let tempDirectory = try! fileManager.contentsOfDirectoryAtPath(NSTemporaryDirectory())
        for file in tempDirectory {
            let filePathToDelete = NSTemporaryDirectory() + file
            try! fileManager.removeItemAtPath(filePathToDelete)
            print(filePathToDelete)
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        previewLayer!.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResize
        print(previewLayer!.frame)
        print(view.bounds)
        print(size)
        print(coordinator)
        print(UIDevice.currentDevice().orientation)
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    //
    // MARK: Actions
    //
    //////////////////////////////////////////////////////////////////////////////////////////
    @IBAction func recordButtonPressed(sender: UIButton) {
        if (!recording) {
            sender.backgroundColor = UIColor.magentaColor()
            print("Now recording")
            self.recordMovie()
            recording = true
        } else {
            sender.backgroundColor = UIColor.cyanColor()
            print("Saving movie...")
            self.saveMovie()
            recording = false
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
}
