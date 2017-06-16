//
//  ViewController.swift
//  RecordKitExample
//
//  Created by goccy on 2017/06/14.
//  Copyright © 2017年 goccy. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import RecordKit

class ViewController: AVPlayerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.playMovieFromProjectBundle()
        RKRecorder.sharedInstance().autoRecord(forSeconds: 3, withDelay: 0)
    }
    
    func playMovieFromProjectBundle() {
        if let bundlePath = Bundle.main.path(forResource: "cat", ofType: "mp4") {
            playMovie(url : URL(fileURLWithPath: bundlePath))
        } else {
            print("no such file")
        }
    }
    
    func playMovie(url :URL) {
        let videoPlayer = AVPlayer(url: url)
        self.player = videoPlayer
        videoPlayer.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

