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
    
    var recording = true
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraDevice: AVCaptureDevice?
    var cameraDeviceInput: AVCaptureDeviceInput?
    var movieOutput: AVCaptureMovieFileOutput?
    var outputURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        cameraDevice = getFrontCamera()
        cameraDeviceInput = try! AVCaptureDeviceInput(device: cameraDevice!)
        
        // Capture session has cameraDevice as an input
        // AVCapture Input
        if ((captureSession?.canAddInput(cameraDeviceInput)) != nil) {
            captureSession?.addInput(cameraDeviceInput)
        }
        
        // MARK: Output
        movieOutput = AVCaptureMovieFileOutput()
        if ((captureSession?.canAddOutput(movieOutput)) != nil) {
            captureSession?.addOutput(movieOutput)
        }
        
        // MARK: Preview Layer ---------------------------------------------
        previewLayer!.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
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
    
    func getFrontCamera() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if device.position == AVCaptureDevicePosition.Front {
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
    
    //////////////////////////////////////////////////////////////////////////////////////////
    //
    // MARK: Actions
    //
    //////////////////////////////////////////////////////////////////////////////////////////
    @IBAction func recordButtonPressed(sender: UIButton) {
        if (recording) {
            sender.backgroundColor = UIColor.magentaColor()
            print("Now recording")
            self.recordMovie()
            recording = false
        } else {
            sender.backgroundColor = UIColor.cyanColor()
            print("Saving movie...")
            self.saveMovie()
            recording = true
        }
    }
}
