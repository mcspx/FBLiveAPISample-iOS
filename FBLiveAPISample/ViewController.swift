//
//  ViewController.swift
//  FBLiveAPI
//
//  Created by LeeSunhyoup on 2016. 9. 17..
//  Copyright © 2016년 Lee Sun-Hyoup. All rights reserved.
//

import UIKit

class ViewController: UIViewController, VCSessionDelegate {
    @IBOutlet var contentView: UIView!
    @IBOutlet var liveButton: UIButton!
    @IBOutlet var livePrivacyControl: UISegmentedControl!
    
    var session: VCSimpleSession!
    var livePrivacy: FBLivePrivacy = .closed
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        liveButton.layer.cornerRadius = 15
        
        session = VCSimpleSession(videoSize: CGSize(width: 1280, height: 720), frameRate: 30, bitrate: 4000000, useInterfaceOrientation: false)
        contentView.addSubview(session.previewView)
        session.previewView.frame = contentView.bounds
        session.delegate = self
    }

    @IBAction func live() {
        switch session.rtmpSessionState {
        case .none, .previewStarted, .ended, .error:
            startFBLive()
        default:
            endFBLive()
            break
        }
    }
    
    func startFBLive() {
        if FBSDKAccessToken.current() != nil {
            FBLiveAPI.shared.startLive(privacy: livePrivacy) { result in
                guard let streamUrlString = (result as? NSDictionary)?.value(forKey: "stream_url") as? String else {
                    return
                }
                let streamUrl = URL(string: streamUrlString)
                
                guard let lastPathComponent = streamUrl?.lastPathComponent,
                    let query = streamUrl?.query else {
                        return
                }
                
                self.session.startRtmpSession(
                    withURL: "rtmp://rtmp-api.facebook.com:80/rtmp/",
                    andStreamKey: "\(lastPathComponent)?\(query)"
                )
                
                self.livePrivacyControl.isUserInteractionEnabled = false
            }
        } else {
            fbLogin()
        }
    }
    
    func endFBLive() {
        if FBSDKAccessToken.current() != nil {
            FBLiveAPI.shared.endLive { _ in
                self.session.endRtmpSession()
                self.livePrivacyControl.isUserInteractionEnabled = true
            }
        } else {
            fbLogin()
        }
    }
    
    func fbLogin() {
        let loginManager = FBSDKLoginManager()
        loginManager.logIn(withPublishPermissions: ["publish_actions"], from: self) { (result, error) in
            if error != nil {
                print("Error")
            } else if result?.isCancelled == true {
                print("Cancelled")
            } else {
                print("Logged in")
            }
        }
    }
    
    @IBAction func changeLivePrivacy(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            livePrivacy = .closed
        case 1:
            livePrivacy = .everyone
        case 2:
            livePrivacy = .allFriends
        case 3:
            livePrivacy = .friendsOfFriends
        default:
            break
        }
    }
    
    // MARK: VCSessionDelegate
    
    func connectionStatusChanged(_ sessionState: VCSessionState) {
        switch session.rtmpSessionState {
        case .starting:
            liveButton.setTitle("Conneting", for: .normal)
            liveButton.backgroundColor = UIColor.orange
        case .started:
            liveButton.setTitle("Disconnect", for: .normal)
            liveButton.backgroundColor = UIColor.red
        default:
            liveButton.setTitle("Live", for: .normal)
            liveButton.backgroundColor = UIColor.green
        }
    }
}

