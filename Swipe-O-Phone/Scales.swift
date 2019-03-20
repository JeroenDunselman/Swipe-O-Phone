//
//  Scales.swift
//  Swipe-O-Phone
//
//  Created by Jeroen Dunselman on 20/03/2019.
//  Copyright © 2019 Jeroen Dunselman. All rights reserved.
//

import Foundation

class Scales {
    
    var scales:[[[Int]]] = [[], [], []]
    private var chordNumbers:[(name: String, numbers: String)] = []
    private let scaleMinA = "17;24;29;32;36;41;44;48;53;56;60;65;68;72"
    private let scaleMajC = "20;24;27;32;36;39;44;48;51;56;60;63;68;72"
    private let scaleMajF = "13;17;20;25;29;32;37;41;44;49;53;56;61;65"
    private let scaleMajG = "15;19;22;27;31;34;39;43;46;51;55;58;63;67"
    private let scaleMnA7 = "17;24;27;32;36;39;41;44;48;51;56;60;63;65;68;72"
    private let scaleMjC7 = "20;24;27;30;32;36;39;42;44;48;51;54;56;60;63;66;68;72"
    private let scaleMjF7 = "13;17;20;23;29;32;35;37;41;44;47;53;56;59;61;65"
    private let scaleMjG7 = "15;19;22;25;31;34;39;43;46;49;51;55;58;63;67"
    private let scaleMnA6 = "17;24;26;32;36;39;41;44;48;51;56;60;63;65;68;72"
    private let scaleMjC6 = "20;24;27;29;32;36;39;41;44;48;51;53;56;60;63;65;68;72"
    private let scaleMjF6 = "13;17;20;22;29;32;34;37;41;44;46;53;56;56;61;65"
    private let scaleMjG6 = "15;19;22;24;31;34;36;39;43;46;48;51;55;57;63;67"
    
    init() {
        chordNumbers.append(("scaleMinA", scaleMinA))
        chordNumbers.append(("scaleMajC", scaleMajC))
        chordNumbers.append(("scaleMajF", scaleMajF))
        chordNumbers.append(("scaleMajG", scaleMajG))
        chordNumbers.append(("scaleMnA7", scaleMnA7))
        chordNumbers.append(("scaleMjC7", scaleMjC7))
        chordNumbers.append(("scaleMjF7", scaleMjF7))
        chordNumbers.append(("scaleMjG7", scaleMjG7))
        chordNumbers.append(("scaleMnA6", scaleMnA6))
        chordNumbers.append(("scaleMjC6", scaleMjC6))
        chordNumbers.append(("scaleMjF6", scaleMjF6))
        chordNumbers.append(("scaleMjG6", scaleMjG6))
        
        for i in 0..<chordNumbers.count {
            let notes:[Int] = chordNumbers[i].numbers.components(separatedBy: ";").map {return Int($0)!}
            
            if i < 4 {
                scales[0].append(notes)
            } else if i < 8 {
                scales[1].append(notes)
            } else {
                scales[2].append(notes)
            }
            
        }
    }
}
