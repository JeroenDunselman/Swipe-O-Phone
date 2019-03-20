//
//  ViewController.swift
//  Swipe-O-Phone
//
//  Created by Jeroen Dunselman on 20/03/2019.
//  Copyright © 2019 Jeroen Dunselman. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI

class ViewController: UIViewController {
    
    var mode = "song"
    var playerArmed = true
    
    let chords = Scales()
    var chordZonesCount = 0
    var chordIndex = 0
    var octaveZonesCount = 3
    var octaveIndex = 1
    var transposeIndex = 0
    var chordVariant = 0 //[1,"7th"], [2, "6th"]
    var fourFingerTranspose = 0 //transposes - 1
    
    let sequence:[Int] = [0, 1, 2, 1, 3, 2, 0, 1]
    var sequenceIndex = 0
    
    var panGesture = UIPanGestureRecognizer()
    var currentVelocity: CGPoint = CGPoint(x: 0, y: 0)
    
    var currentNote:Int = 64
    let releaseTime: Double = 0.5
    var timerNoteOff: Timer?
    
    //    let conductor = Conductor()
    
    let octaveBank = AKOscillatorBank()
    let mixer = AKMixer()
    //    let t = AKTuningTable().presetHighlandBagPipes()
    let bank = AKOscillatorBank()
    let d = AKFlute()
    //    let s = AKSampler()
    let mandolin = AKMandolin()
    var pluckPosition = 0.2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        d.outputNode.setTun
        chordZonesCount = chords.scales[0].count
        getGuideLandscape()
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.play(_:)))
        self.panGesture.maximumNumberOfTouches = 4
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(panGesture)
        
        cell()
        
        d.connect(to: mixer)
        bank.connect(to: mixer)
        octaveBank.connect(to: mixer)
        
        AudioKit.output = mixer //envelope
        
        mandolin.detune = 1
        mandolin.bodySize = 1
        let delay = AKDelay(mandolin)
        delay.time = 0.6108 //1.5 / playRate
        delay.dryWetMix = 0.05
        delay.feedback = 0.05
        
        let reverb = AKReverb(delay)
        
        AudioKit.output = reverb
        
        do {
            try AudioKit.start()
            AKLog("AudioKit started")
        } catch {
            AKLog("AudioKit did not start!")
        }
    }
    
    let colors = [UIColor.blue, UIColor.red, UIColor.green, UIColor.yellow]
    var guides: [UIView] = []
    
    func getGuideLandscape() {
        for i in 0..<chordZonesCount {
            let g = UIView()
            g.alpha = 0.0
            
            let xPos = CGFloat(i) * (self.view.bounds.width / CGFloat(chordZonesCount ))
            g.frame = CGRect(origin: CGPoint(x: xPos, y: 0),
                             size: CGSize(width: self.view.bounds.width / CGFloat(chordZonesCount),
                                          height: self.view.bounds.height ))
            let h = UIImageView()
            h.frame = CGRect(origin: CGPoint(x: 10, y: 10),
                             size: CGSize(width: g.bounds.width - 10,
                                          height: g.bounds.height - 10))
            h.backgroundColor = colors[i]
            g.addSubview(h)
            
            //            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            //            g.addSubview(blur)
            
            guides.append(g)
            self.view.addSubview(g)
        }
    }
    func getGuide() {
        for i in 0..<chordZonesCount {
            let g = UIView()
            g.alpha = 0.0
            
            let yPos = CGFloat(i) * (self.view.bounds.height / CGFloat(chordZonesCount ))
            g.frame = CGRect(origin: CGPoint(x: 0, y: yPos),
                             size: CGSize(width: self.view.bounds.width,
                                          height: self.view.bounds.height / CGFloat(chordZonesCount)))
            let h = UIImageView()
            h.frame = CGRect(origin: CGPoint(x: 10, y: 10),
                             size: CGSize(width: g.bounds.width - 10,
                                          height: g.bounds.height - 10))
            h.backgroundColor = colors[i]
            g.addSubview(h)
            
            //            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            //            g.addSubview(blur)
            
            guides.append(g)
            self.view.addSubview(g)
        }
    }
    
    @objc func play(_ sender:UIPanGestureRecognizer){
        
        let pos = sender.location(in: self.view)
        let velocity = sender.velocity(in: self.view)
        
        updateUI()
        handleFingerCount(sender)
        handlePan(pos: pos)
        
        //playmode changes
        if (sender.state == UIGestureRecognizer.State.began) {   handleModeChange(pos: pos) }
        
        //next phrase
        if mode == "harp" { handleHarp(pos: pos) }
        if mode == "song" && playerArmed {
            self.playNextNote()
            playerArmed = false
            handleChordChange()
        }
        
        //transport sequence to next note?
        if mode == "song" {
            //detect change of direction of pan
            if((velocity.y > 0 && currentVelocity.y < 0) || (velocity.y < 0 && currentVelocity.y > 0)) {
                //trigger next note
                sequenceIndex += 1
                self.playNextNote()
                //[self setAnimationToNote]
            }
        }
        currentVelocity.y = velocity.y
        
        //release
        //postpone while panning
        if !(timerNoteOff == nil) {
            //cancel previous noteOff
            timerNoteOff?.invalidate()
            timerNoteOff = nil
        }
        //reset timer to invoke noteOff after pan ended
        self.timerNoteOff = Timer.scheduledTimer(timeInterval: releaseTime, target:self, selector: #selector(self.triggerNoteOffEvent), userInfo: nil, repeats: true)
    }
    
    @objc func triggerNoteOffEvent() {
        timerNoteOff?.invalidate()
        timerNoteOff = nil
        
        _ = (0..<128).map { noteOff(note: MIDINoteNumber($0)) }
        
        sequenceIndex = 0
        playerArmed = true
        
        for g in guides {UIView.animate(withDuration: 0.4) {g.alpha = 0.0} }
        emitterLayer.birthRate = 0
        
        //    vwBtnShowHideSetting.alpha = 0.7
        //    isVisibleVwBtnShowHideSetting = true
    }
    
    func handlePan(pos: CGPoint) {
        
        //chord changes
        let chordFromLocation = min(
            Int((pos.x/self.view.bounds.size.width) * CGFloat(chordZonesCount)),
            chordZonesCount - 1)
        if chordIndex != chordFromLocation {
            chordIndex = chordFromLocation
            handleChordChange()
        }
        
        //oct changes
        let octaveFromLocation = Int((pos.y / self.view.bounds.size.height) * CGFloat(octaveZonesCount))
        if (octaveIndex != octaveFromLocation) {
            octaveIndex = octaveFromLocation
            //            print("\(octaveIndex)")
        }
        
        //animate
        emitterLayer.emitterPosition = pos
        var velo = currentVelocity.y / 16
        if (velo < 0) { velo = velo * -1 }
        
        emitterLayer.birthRate = Float(velo)
        
    }
    
    func handleChordChange() {
        //        guide showhide        print("handleChordChange, \(chordIndex)")
        for i in 0..<chordZonesCount{
            let alphaValue:CGFloat = i == chordIndex ? 0.7 : 0.0
            UIView.animate(withDuration: 0.4) {
                self.guides[i].alpha = alphaValue
            }
        }
        
        emitterLayer.setValue(colors[colors.count.asMaxRandom()].cgColor, forKey: "emitterCells.fire.color")
    }
    
    func handleFingerCount(_ sender:UIPanGestureRecognizer) {
        
        if (sender.numberOfTouches == 4) {
            fourFingerTranspose = -1;
            self.chordVariant = 0
        } else {
            fourFingerTranspose = 0;
            self.chordVariant = max(sender.numberOfTouches  - 1, 0)
        }
    }
    
    func playNextNote() {
        noteOff(note: MIDINoteNumber(currentNote))
        
        //        print("sequenceIndex: \(sequenceIndex)")
        //        print("octave :\(octaveIndex)   chordIndex :\(chordIndex)")
        //         print("chordVariant :\(self.chordVariant)")
        //        x :\(prevVelo.x) y :\(prevVelo.y)
        //        rsm :\(resumePlayAtNextPan)
        //        harp :\(harpIndex)\n  fourFingerTranspose :\(fourFingerTranspose)
        
        //loop sequence
        if sequenceIndex >= sequence.count { sequenceIndex = 0 }
        var octav = 0
        if octaveIndex == 0 {octav = -12}
        if octaveIndex == 2 {octav = 12}
        currentNote = octav + 40 + chords.scales[self.chordVariant][self.chordIndex][sequence[sequenceIndex]] + fourFingerTranspose
        //        print("\(currentNote)"
        //        envelope.start()
        noteOn(note: MIDINoteNumber(currentNote))
    }
    
    func noteOn(note: MIDINoteNumber) {
        //        conductor.play(noteNumber: 64) //, velocity: 80)
        //        octaveBank.play(noteNumber: note + 12, velocity: 80)
        //        bank.play(noteNumber: note, velocity: 80)
        mandolin.fret(noteNumber: note, course: 1)
        mandolin.pluck(course: 1, position: pluckPosition, velocity: 127)
        
    }
    
    func noteOff(note: MIDINoteNumber) {
        //        conductor.stop(noteNumber: 64)
        //        bank.stop(noteNumber: note)
        //        octaveBank.stop(noteNumber: note + 12)
    }
    
    var harpIndex = 1
    func handleHarp(pos: CGPoint) {
        let maxStringsOnScreen = 12 //[arrSong count];
        let harpIndexFromLocation = Int((pos.x/self.view.bounds.size.width) * CGFloat(maxStringsOnScreen))
        //        NSLog(@"harpIndex :   %d", harpIndex);
        
        if harpIndexFromLocation != harpIndex || playerArmed {
            harpIndex = harpIndexFromLocation
            self.playNextNote()
            playerArmed = false
            sequenceIndex += 1
        }
    }
    
    //InitPlayModeFromViewEdges
    func handleModeChange(pos: CGPoint) {
        
        print("\(transposeIndex)")
        print("\(mode)")
        let range = 50
        if (pos.x < CGFloat(range)) || (pos.x > (CGFloat(self.view.bounds.size.width) - CGFloat(range)) ) {//            NSLog(@"At border");
            //#pragma mark crash: more digits set in seq than exist in chordscales (~14)
            mode = "harp"
            
        } else if (pos.y < CGFloat(range)) {
            mode = "transpose-V"
            transposeIndex -= 1
        } else if (pos.y > (CGFloat(self.view.bounds.size.height) - CGFloat(range)) ){
            mode = "transposeV"
            transposeIndex += 1
        } else { //            NSLog(@"Not at border");
            mode = "song"
        }
        
        //disable other modes
        mode = "song"
        
    }
    
    var birthrate = 0
    let emitterLayer = CAEmitterLayer()
    func cell() {
        let fire = CAEmitterCell()
        
        fire.birthRate = 1
        fire.lifetime = 3.0
        fire.lifetimeRange = 3.0
        //        fire.color = UIColor( red: CGFloat(0.2), green: CGFloat(0.4), blue: CGFloat(0.8), alpha: CGFloat(0.1) ).cgColor
        fire.color = UIColor.cyan.cgColor
        fire.redRange = 0.46
        fire.greenRange = 0.49
        fire.blueRange = 0.67
        fire.alphaRange = 0.55
        
        fire.redSpeed = 0.11
        fire.greenSpeed = 0.07
        fire.blueSpeed = -2.25
        fire.alphaSpeed = -1.5
        //    345px-Chladini.Diagrams
        fire.contents = #imageLiteral(resourceName: "345px-Chladini2").cgImage
        fire.velocity = 10.0
        fire.velocityRange = 20.0
        fire.emissionRange = .pi * 2
        
        fire.scaleSpeed = -0.25
        fire.spin = 0.3
        fire.spinRange = 8.0
        fire.scale = 1.0
        fire.name = "fire"
        
        //add the cell to the layer and we're done
        //        fireEmitter.emitterCells = [NSArray arrayWithObject:fire];
        
        emitterLayer.emitterCells = [fire]
        emitterLayer.emitterMode = CAEmitterLayerEmitterMode.outline
        emitterLayer.emitterShape = CAEmitterLayerEmitterShape.circle
        emitterLayer.emitterSize = CGSize(width: 5, height: 5)
        
        view.layer.addSublayer(emitterLayer)
    }
    
    func updateUI() {
        /*if (isVisibleVwBtnShowHideSetting){
         [self hideVwBtnShowHideSetting];
         [self dismissKeyboard];}*/
        
        /*//soundctrl changes if (isVisibleVwSettings) { controlValue = ((self.view.bounds.size.height- pos2.y)/self.view.bounds.size.height)*maxCtrlVal;
         [sgmCtrl setTitle:[[NSString alloc] initWithFormat:@"%d", controlValue ] forSegmentAtIndex:sgmCtrl.selectedSegmentIndex];
         self->audioData.voicer->controlChange(controlType, controlValue); } */
        
        
        /*        //    lblChord.setTitle [lblChord setText:[[NSString alloc] initWithFormat:@"%d", counter]];
         [lblChord setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];*/
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension Int {
    
    func asMaxRandom() -> Int {
        let maximum = self
        return Int({Int(arc4random_uniform(UInt32(maximum)))}())
    }
}

