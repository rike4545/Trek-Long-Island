// Copyright Bryan Carroll. All rights reserved.
//
//  TLStarTrekTriviaBank.swift
//  Trek Long Island
//
//  Star Trek Trivia — 200 questions
//  Swift 6 • iOS 17+
//
//  Drop this file into your Trek Long Island target.
//  Use: TLStarTrekTriviaBank.allQuestions
//

import Foundation

public struct TLTriviaQuestion: Identifiable, Hashable, Codable {

    public enum Difficulty: String, Codable, CaseIterable {
        case easy, medium, hard
    }

    public let id: Int
    public let category: String
    public let difficulty: Difficulty

    public let prompt: String
    public let choices: [String]          // typically 4 choices
    public let answerIndex: Int           // 0-based index into `choices`
    public let explanation: String?

    public init(
        id: Int,
        category: String,
        difficulty: Difficulty,
        prompt: String,
        choices: [String],
        answerIndex: Int,
        explanation: String? = nil
    ) {
        self.id = id
        self.category = category
        self.difficulty = difficulty
        self.prompt = prompt
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
    }

    public var answer: String {
        guard choices.indices.contains(answerIndex) else { return "" }
        return choices[answerIndex]
    }
}

public enum TLStarTrekTriviaBank {

    public static let allQuestions: [TLTriviaQuestion] = [
        // MARK: - TOS (1–20)

        .init(id: 1, category: "TOS", difficulty: .easy, prompt: "Who is the captain of the USS Enterprise (NCC-1701) in Star Trek: The Original Series?", choices: ["James T. Kirk", "Jean-Luc Picard", "Kathryn Janeway", "Jonathan Archer"], answerIndex: 0, explanation: "Kirk commands the Enterprise in TOS."),
        .init(id: 2, category: "TOS", difficulty: .easy, prompt: "Who is the Enterprise's Vulcan first officer in TOS?", choices: ["Spock", "Tuvok", "T'Pol", "Sarek"], answerIndex: 0, explanation: "Spock serves as first officer and science officer."),
        .init(id: 3, category: "TOS", difficulty: .easy, prompt: "What is Dr. Leonard McCoy's nickname?", choices: ["Bones", "Doc", "Scalpel", "Meds"], answerIndex: 0, explanation: "McCoy is often called “Bones.”"),
        .init(id: 4, category: "TOS", difficulty: .easy, prompt: "Who is the Enterprise's chief engineer in TOS?", choices: ["Montgomery Scott", "Geordi La Forge", "B'Elanna Torres", "Charles Tucker III"], answerIndex: 0, explanation: "Scotty is the chief engineer in TOS."),
        .init(id: 5, category: "TOS", difficulty: .easy, prompt: "What is Uhura's primary role aboard the Enterprise in TOS?", choices: ["Communications officer", "Chief engineer", "Helmsman", "Security chief"], answerIndex: 0, explanation: "Uhura runs ship communications."),
        .init(id: 6, category: "TOS", difficulty: .easy, prompt: "What is Sulu's primary duty on the Enterprise in TOS?", choices: ["Helm/navigation", "Chief medical officer", "Ship's counselor", "Chief of security"], answerIndex: 0, explanation: "Sulu frequently serves at the helm/navigation station."),
        .init(id: 7, category: "TOS", difficulty: .easy, prompt: "What is the registry number of Kirk's Enterprise?", choices: ["NCC-1701", "NCC-74656", "NX-01", "NCC-1701-D"], answerIndex: 0, explanation: "The original Enterprise is NCC-1701."),
        .init(id: 8, category: "TOS", difficulty: .easy, prompt: "What is the standard handheld energy weapon used by Starfleet crews in TOS?", choices: ["Phaser", "Blaster", "Needler", "Pulse rifle"], answerIndex: 0, explanation: "Starfleet commonly uses phasers."),
        .init(id: 9, category: "TOS", difficulty: .easy, prompt: "What technology allows Starfleet ships to travel faster than light?", choices: ["Warp drive", "Slipstream drive", "Hyperdrive", "Jump gate"], answerIndex: 0, explanation: "Warp drive enables faster-than-light travel."),
        .init(id: 10, category: "TOS", difficulty: .easy, prompt: "What is the name of Kirk's ship in TOS?", choices: ["USS Enterprise", "USS Defiant", "USS Voyager", "USS Discovery"], answerIndex: 0, explanation: "Kirk commands the USS Enterprise."),
        .init(id: 11, category: "TOS", difficulty: .medium, prompt: "What is the name of Spock's father?", choices: ["Sarek", "Syrran", "T'Pel", "Vorik"], answerIndex: 0, explanation: "Sarek is Spock’s Vulcan father."),
        .init(id: 12, category: "TOS", difficulty: .medium, prompt: "What is the name of Spock's mother?", choices: ["Amanda Grayson", "Lwaxana Troi", "T'Pol", "Erika Hernandez"], answerIndex: 0, explanation: "Amanda Grayson is Spock’s human mother."),
        .init(id: 13, category: "TOS", difficulty: .easy, prompt: "Which phrase is commonly paired with the Vulcan salute?", choices: ["Live long and prosper", "Make it so", "Qapla'", "Engage"], answerIndex: 0, explanation: "The salute is associated with “Live long and prosper.”"),
        .init(id: 14, category: "TOS", difficulty: .medium, prompt: "In TOS, what furry creature multiplies rapidly in the episode 'The Trouble with Tribbles'?", choices: ["Tribbles", "Greebles", "Mogwai", "Targs"], answerIndex: 0, explanation: "Tribbles are the rapidly multiplying creatures."),
        .init(id: 15, category: "TOS", difficulty: .easy, prompt: "Spock is best described as which of the following?", choices: ["Half-Vulcan, half-human", "Human", "Klingon", "Android"], answerIndex: 0, explanation: "Spock is the son of a Vulcan father and a human mother."),
        .init(id: 16, category: "TOS", difficulty: .medium, prompt: "The Prime Directive is also known by what designation?", choices: ["General Order 1", "Section 31", "Order 66", "Directive 9"], answerIndex: 0, explanation: "In Star Trek, the Prime Directive is General Order 1."),
        .init(id: 17, category: "TOS", difficulty: .medium, prompt: "What is the name of the super-intelligent space probe in the TOS episode 'The Changeling'?", choices: ["Nomad", "V'Ger", "M-5", "Tin Man"], answerIndex: 0, explanation: "Nomad is the probe in 'The Changeling.'"),
        .init(id: 18, category: "TOS", difficulty: .medium, prompt: "In 'The City on the Edge of Forever', what ancient portal enables time travel?", choices: ["The Guardian of Forever", "The Nexus", "The Bajoran Orb", "The Time Crystal"], answerIndex: 0, explanation: "Kirk and Spock use the Guardian of Forever."),
        .init(id: 19, category: "TOS", difficulty: .easy, prompt: "What is the name of the Vulcan homeworld?", choices: ["Vulcan", "Romulus", "Qo'noS", "Andoria"], answerIndex: 0, explanation: "Vulcan is the Vulcan homeworld."),
        .init(id: 20, category: "TOS", difficulty: .medium, prompt: "Which of these is a famous line associated with Spock’s logic?", choices: ["The needs of the many outweigh the needs of the few", "Do or do not, there is no try", "Winter is coming", "I am your father"], answerIndex: 0, explanation: "Spock’s quote is featured prominently in Star Trek II and beyond."),

        // MARK: - TNG (21–45)

        .init(id: 21, category: "TNG", difficulty: .easy, prompt: "Who is the captain of the USS Enterprise-D?", choices: ["Jean-Luc Picard", "James T. Kirk", "Benjamin Sisko", "Hikaru Sulu"], answerIndex: 0, explanation: "Picard commands the Enterprise-D."),
        .init(id: 22, category: "TNG", difficulty: .easy, prompt: "The USS Enterprise-D is what class of starship?", choices: ["Galaxy-class", "Intrepid-class", "Constitution-class", "Defiant-class"], answerIndex: 0, explanation: "Enterprise-D is a Galaxy-class starship."),
        .init(id: 23, category: "TNG", difficulty: .easy, prompt: "Which command is Picard especially known for saying on the bridge?", choices: ["Make it so", "Fire everything", "Punch it", "Full speed ahead, Mr. Sulu"], answerIndex: 0, explanation: "“Make it so” is one of Picard’s signature lines."),
        .init(id: 24, category: "TNG", difficulty: .easy, prompt: "How does Picard commonly order his tea?", choices: ["Earl Grey, hot", "Chamomile, iced", "Green tea, sweet", "Coffee, black"], answerIndex: 0, explanation: "Picard’s go-to is “Earl Grey, hot.”"),
        .init(id: 25, category: "TNG", difficulty: .easy, prompt: "Who is the Enterprise-D's first officer?", choices: ["William Riker", "Geordi La Forge", "Data", "Wesley Crusher"], answerIndex: 0, explanation: "Riker is Picard’s first officer."),
        .init(id: 26, category: "TNG", difficulty: .easy, prompt: "Who is the chief engineer of the Enterprise-D for most of TNG?", choices: ["Geordi La Forge", "Montgomery Scott", "Reginald Barclay", "Miles O'Brien"], answerIndex: 0, explanation: "La Forge serves as chief engineer."),
        .init(id: 27, category: "TNG", difficulty: .easy, prompt: "What is Data’s species/type?", choices: ["Android", "Vulcan", "Betazoid", "Trill"], answerIndex: 0, explanation: "Data is an android."),
        .init(id: 28, category: "TNG", difficulty: .medium, prompt: "Who created Data?", choices: ["Dr. Noonien Soong", "Zefram Cochrane", "Lewis Zimmerman", "Richard Daystrom"], answerIndex: 0, explanation: "Data was created by Dr. Noonien Soong."),
        .init(id: 29, category: "TNG", difficulty: .easy, prompt: "What is the name of Data’s cat?", choices: ["Spot", "Porthos", "Grudge", "Targ"], answerIndex: 0, explanation: "Data’s cat is Spot."),
        .init(id: 30, category: "TNG", difficulty: .medium, prompt: "What is the name of Data’s android 'brother'?", choices: ["Lore", "B-4", "Soji", "Lal"], answerIndex: 0, explanation: "Lore is Data’s older and unstable 'brother.'"),
        .init(id: 31, category: "TNG", difficulty: .easy, prompt: "What species is Worf?", choices: ["Klingon", "Romulan", "Human", "Cardassian"], answerIndex: 0, explanation: "Worf is Klingon."),
        .init(id: 32, category: "TNG", difficulty: .medium, prompt: "What Klingon exclamation is often used to mean 'success' or 'well done'?", choices: ["Qapla'", "Kapow", "Klaatu", "Shaka"], answerIndex: 0, explanation: "“Qapla'” is a common Klingon exclamation."),
        .init(id: 33, category: "TNG", difficulty: .easy, prompt: "What species is Deanna Troi?", choices: ["Betazoid", "Vulcan", "Trill", "Bajoran"], answerIndex: 0, explanation: "Troi is half-Betazoid (commonly referred to as Betazoid)."),
        .init(id: 34, category: "TNG", difficulty: .easy, prompt: "Who is the Enterprise-D’s chief medical officer?", choices: ["Beverly Crusher", "Julian Bashir", "Leonard McCoy", "Phlox"], answerIndex: 0, explanation: "Dr. Beverly Crusher is the CMO."),
        .init(id: 35, category: "TNG", difficulty: .easy, prompt: "What is the name of Dr. Crusher’s son?", choices: ["Wesley Crusher", "Jake Sisko", "Harry Kim", "Travis Mayweather"], answerIndex: 0, explanation: "Wesley Crusher is her son."),
        .init(id: 36, category: "TNG", difficulty: .medium, prompt: "Who was the Enterprise-D’s first chief of security in Season 1?", choices: ["Tasha Yar", "Worf", "Odo", "Kira Nerys"], answerIndex: 0, explanation: "Lieutenant Tasha Yar served as chief of security early on."),
        .init(id: 37, category: "TNG", difficulty: .medium, prompt: "Which being repeatedly tests humanity and Picard?", choices: ["Q", "The Traveler", "The Caretaker", "The Founder Leader"], answerIndex: 0, explanation: "Q is a recurring godlike antagonist/instigator."),
        .init(id: 38, category: "TNG", difficulty: .easy, prompt: "Which cybernetic collective is known for assimilating other species?", choices: ["The Borg", "The Dominion", "The Ferengi Alliance", "Section 31"], answerIndex: 0, explanation: "The Borg assimilate individuals and cultures."),
        .init(id: 39, category: "TNG", difficulty: .easy, prompt: "Which phrase is most associated with the Borg?", choices: ["Resistance is futile", "Live long and prosper", "Make it so", "There are four lights"], answerIndex: 0, explanation: "The Borg often declare, “Resistance is futile.”"),
        .init(id: 40, category: "TNG", difficulty: .medium, prompt: "After assimilation, Picard is given what Borg designation?", choices: ["Locutus of Borg", "One of Ten", "Omega Prime", "Delta One"], answerIndex: 0, explanation: "Picard becomes Locutus of Borg."),
        .init(id: 41, category: "TNG", difficulty: .medium, prompt: "Who became Klingon Chancellor after K'mpec’s death in TNG?", choices: ["Gowron", "Martok", "Kor", "Chang"], answerIndex: 0, explanation: "Gowron rises to the chancellorship."),
        .init(id: 42, category: "TNG", difficulty: .medium, prompt: "What is the name of Worf’s son?", choices: ["Alexander Rozhenko", "K'Ehleyr", "Mogh", "Nog"], answerIndex: 0, explanation: "Worf’s son is Alexander."),
        .init(id: 43, category: "TNG", difficulty: .medium, prompt: "Which position does Data typically hold on the Enterprise-D bridge?", choices: ["Operations officer", "Chief engineer", "Chief medical officer", "Ship's counselor"], answerIndex: 0, explanation: "Data commonly serves as operations officer."),
        .init(id: 44, category: "TNG", difficulty: .easy, prompt: "What is the Enterprise’s main holographic recreation facility called?", choices: ["Holodeck", "Sim Room", "HoloBay", "Dream Chamber"], answerIndex: 0, explanation: "The ship uses the Holodeck for simulations."),
        .init(id: 45, category: "TNG", difficulty: .hard, prompt: "Which TNG two-part story features the Borg attack that leads to Picard becoming Locutus?", choices: ["The Best of Both Worlds", "Chain of Command", "Yesterday's Enterprise", "Redemption"], answerIndex: 0, explanation: "“The Best of Both Worlds” is the key Borg two-parter."),

        // MARK: - DS9 (46–65)

        .init(id: 46, category: "DS9", difficulty: .easy, prompt: "Deep Space Nine was originally a Cardassian station known as what?", choices: ["Terok Nor", "Empok Nor", "Bajor Prime", "Arkaria Base"], answerIndex: 0, explanation: "The station was Terok Nor under Cardassian control."),
        .init(id: 47, category: "DS9", difficulty: .easy, prompt: "Who is the commanding officer of Deep Space Nine at the start of the series?", choices: ["Benjamin Sisko", "Jean-Luc Picard", "Kathryn Janeway", "James T. Kirk"], answerIndex: 0, explanation: "Sisko is placed in command of DS9."),
        .init(id: 48, category: "DS9", difficulty: .easy, prompt: "Sisko is known to Bajorans by what title connected to their religion?", choices: ["The Emissary", "The Kai", "The Nagus", "The Chancellor"], answerIndex: 0, explanation: "Bajorans consider Sisko the Emissary of the Prophets."),
        .init(id: 49, category: "DS9", difficulty: .easy, prompt: "Which Bajoran officer serves as Sisko’s second-in-command?", choices: ["Kira Nerys", "Jadzia Dax", "Beverly Crusher", "Tasha Yar"], answerIndex: 0, explanation: "Major Kira Nerys is DS9’s Bajoran liaison and key officer."),
        .init(id: 50, category: "DS9", difficulty: .easy, prompt: "What is Odo’s species?", choices: ["Changeling", "Vorta", "Trill", "Andorian"], answerIndex: 0, explanation: "Odo is a Changeling (a Founder species)."),
        .init(id: 51, category: "DS9", difficulty: .easy, prompt: "Jadzia Dax is a joined member of which species?", choices: ["Trill", "Bajoran", "Human", "Vulcan"], answerIndex: 0, explanation: "Dax is a Trill symbiont joined with a host."),
        .init(id: 52, category: "DS9", difficulty: .easy, prompt: "What is the name of the symbiont carried by Jadzia and later Ezri?", choices: ["Dax", "Krios", "Talos", "Sarek"], answerIndex: 0, explanation: "Both hosts carry the Dax symbiont."),
        .init(id: 53, category: "DS9", difficulty: .easy, prompt: "Who runs the bar on Deep Space Nine?", choices: ["Quark", "Neelix", "Guinan", "Morn"], answerIndex: 0, explanation: "Quark owns and runs the DS9 bar."),
        .init(id: 54, category: "DS9", difficulty: .medium, prompt: "Which Cardassian is famous for being a tailor with a mysterious past?", choices: ["Elim Garak", "Dukat", "Damar", "Gul Madred"], answerIndex: 0, explanation: "Garak is a tailor—and much more."),
        .init(id: 55, category: "DS9", difficulty: .easy, prompt: "Who is DS9’s chief medical officer?", choices: ["Julian Bashir", "Leonard McCoy", "Phlox", "Beverly Crusher"], answerIndex: 0, explanation: "Dr. Julian Bashir is DS9’s main doctor."),
        .init(id: 56, category: "DS9", difficulty: .medium, prompt: "Who is DS9’s chief of operations?", choices: ["Miles O'Brien", "Geordi La Forge", "Data", "Harry Kim"], answerIndex: 0, explanation: "Chief O’Brien becomes DS9’s chief of operations."),
        .init(id: 57, category: "DS9", difficulty: .easy, prompt: "Which Starfleet ship is assigned to DS9 as a dedicated warship?", choices: ["USS Defiant", "USS Enterprise-D", "USS Voyager", "USS Excelsior"], answerIndex: 0, explanation: "The Defiant is assigned to DS9."),
        .init(id: 58, category: "DS9", difficulty: .medium, prompt: "What is the stable wormhole near DS9 most famous for connecting to?", choices: ["The Gamma Quadrant", "The Delta Quadrant", "The Mirror Universe", "The Nexus"], answerIndex: 0, explanation: "The Bajoran Wormhole opens into the Gamma Quadrant."),
        .init(id: 59, category: "DS9", difficulty: .easy, prompt: "What do Bajorans call the entities living in the wormhole?", choices: ["The Prophets", "The Founders", "The Q", "The Ancients"], answerIndex: 0, explanation: "Bajorans revere them as the Prophets."),
        .init(id: 60, category: "DS9", difficulty: .medium, prompt: "The Dominion’s shapeshifting leaders are known as what?", choices: ["Founders", "Vorta", "Jem'Hadar", "Obsidian Order"], answerIndex: 0, explanation: "The Founders are the Dominion’s Changeling rulers."),
        .init(id: 61, category: "DS9", difficulty: .medium, prompt: "What are the Jem'Hadar within the Dominion?", choices: ["Soldiers", "Scientists", "Religious leaders", "Merchants"], answerIndex: 0, explanation: "Jem’Hadar are the Dominion’s primary soldiers."),
        .init(id: 62, category: "DS9", difficulty: .medium, prompt: "What are the Vorta within the Dominion?", choices: ["Administrators and diplomats", "Starship engineers", "Front-line soldiers", "Independent traders"], answerIndex: 0, explanation: "Vorta serve as managers, diplomats, and overseers."),
        .init(id: 63, category: "DS9", difficulty: .easy, prompt: "What is the title of the Bajoran spiritual leader?", choices: ["Kai", "Chancellor", "Grand Nagus", "Praetor"], answerIndex: 0, explanation: "The Kai is Bajor’s top religious leader."),
        .init(id: 64, category: "DS9", difficulty: .medium, prompt: "Which Kai is a major political and religious figure for much of DS9?", choices: ["Winn Adami", "Opaka Sulan", "T'Lar", "Ishka"], answerIndex: 0, explanation: "Kai Winn is a prominent figure through much of the series."),
        .init(id: 65, category: "DS9", difficulty: .hard, prompt: "What was DS9’s frequent lounge patron known for saying almost nothing at all?", choices: ["Morn", "Quark", "Rom", "Nog"], answerIndex: 0, explanation: "Morn is the famously quiet regular."),

        // MARK: - VOY (66–83)

        .init(id: 66, category: "VOY", difficulty: .easy, prompt: "Who is the captain of the USS Voyager?", choices: ["Kathryn Janeway", "Hikaru Sulu", "Benjamin Sisko", "Jonathan Archer"], answerIndex: 0, explanation: "Janeway commands Voyager."),
        .init(id: 67, category: "VOY", difficulty: .easy, prompt: "USS Voyager is what class of starship?", choices: ["Intrepid-class", "Galaxy-class", "Constitution-class", "Sovereign-class"], answerIndex: 0, explanation: "Voyager is an Intrepid-class ship."),
        .init(id: 68, category: "VOY", difficulty: .easy, prompt: "Voyager is stranded in which quadrant for most of the series?", choices: ["Delta Quadrant", "Alpha Quadrant", "Beta Quadrant", "Gamma Quadrant"], answerIndex: 0, explanation: "Voyager is stranded in the Delta Quadrant."),
        .init(id: 69, category: "VOY", difficulty: .easy, prompt: "Voyager’s main doctor is what kind of program?", choices: ["Emergency Medical Hologram (EMH)", "Android", "Q", "Changeling"], answerIndex: 0, explanation: "The Doctor is the EMH."),
        .init(id: 70, category: "VOY", difficulty: .easy, prompt: "What is Voyager’s EMH commonly called by the crew?", choices: ["The Doctor", "Bones", "Doc Brown", "Medic One"], answerIndex: 0, explanation: "He’s usually referred to simply as “The Doctor.”"),
        .init(id: 71, category: "VOY", difficulty: .easy, prompt: "Which ex-Borg becomes a key member of Voyager’s crew?", choices: ["Seven of Nine", "Locutus", "Hugh", "The Borg Queen"], answerIndex: 0, explanation: "Seven of Nine joins Voyager."),
        .init(id: 72, category: "VOY", difficulty: .medium, prompt: "What is Seven of Nine’s human name?", choices: ["Annika Hansen", "Hannah Bates", "Sonya Gomez", "Erika Benteen"], answerIndex: 0, explanation: "Seven’s human name is Annika Hansen."),
        .init(id: 73, category: "VOY", difficulty: .easy, prompt: "Who is Voyager’s Vulcan security officer?", choices: ["Tuvok", "Spock", "Sarek", "Vorik"], answerIndex: 0, explanation: "Tuvok is Voyager’s Vulcan tactical/security officer."),
        .init(id: 74, category: "VOY", difficulty: .easy, prompt: "Who is the Talaxian who serves as a guide and morale officer early on?", choices: ["Neelix", "Quark", "Nog", "Garak"], answerIndex: 0, explanation: "Neelix becomes Voyager’s morale officer/cook."),
        .init(id: 75, category: "VOY", difficulty: .easy, prompt: "Who is Voyager’s chief engineer for most of the series?", choices: ["B'Elanna Torres", "Geordi La Forge", "Montgomery Scott", "Trip Tucker"], answerIndex: 0, explanation: "B’Elanna Torres is chief engineer."),
        .init(id: 76, category: "VOY", difficulty: .easy, prompt: "Who is Voyager’s first officer?", choices: ["Chakotay", "Harry Kim", "Tom Paris", "Tuvok"], answerIndex: 0, explanation: "Chakotay is Janeway’s first officer."),
        .init(id: 77, category: "VOY", difficulty: .medium, prompt: "What species is Kes?", choices: ["Ocampa", "Trill", "Bajoran", "Andorian"], answerIndex: 0, explanation: "Kes is an Ocampa."),
        .init(id: 78, category: "VOY", difficulty: .easy, prompt: "Who is Voyager’s pilot known for his checkered past?", choices: ["Tom Paris", "Wesley Crusher", "Travis Mayweather", "Hikaru Sulu"], answerIndex: 0, explanation: "Tom Paris is the pilot with a complicated history."),
        .init(id: 79, category: "VOY", difficulty: .hard, prompt: "What is the name of Tom Paris’s father?", choices: ["Admiral Owen Paris", "Admiral Marcus", "Admiral Nechayev", "Admiral Ross"], answerIndex: 0, explanation: "Tom Paris’s father is Admiral Owen Paris."),
        .init(id: 80, category: "VOY", difficulty: .medium, prompt: "Species 8472 originates from what realm?", choices: ["Fluidic space", "The Mirror Universe", "Subspace", "The Nexus"], answerIndex: 0, explanation: "Species 8472 comes from fluidic space."),
        .init(id: 81, category: "VOY", difficulty: .medium, prompt: "What type of faster-travel network do the Borg use that Voyager often encounters?", choices: ["Transwarp conduits", "Stargates", "Slipstream lanes", "Warp tunnels"], answerIndex: 0, explanation: "The Borg famously use transwarp conduits."),
        .init(id: 82, category: "VOY", difficulty: .medium, prompt: "What is the title of Voyager’s series finale?", choices: ["Endgame", "Caretaker", "Scorpion", "Year of Hell"], answerIndex: 0, explanation: "“Endgame” is Voyager’s finale."),
        .init(id: 83, category: "VOY", difficulty: .medium, prompt: "What is the name of the shuttlecraft designed by Tom Paris and Harry Kim?", choices: ["Delta Flyer", "Runabout", "Type-6", "Peregrine"], answerIndex: 0, explanation: "They build and fly the Delta Flyer."),

        // MARK: - ENT (84–92)

        .init(id: 84, category: "ENT", difficulty: .easy, prompt: "Who is the captain of the Enterprise NX-01?", choices: ["Jonathan Archer", "James T. Kirk", "Jean-Luc Picard", "Kathryn Janeway"], answerIndex: 0, explanation: "Archer commands the NX-01."),
        .init(id: 85, category: "ENT", difficulty: .easy, prompt: "What is the registry of Archer’s ship?", choices: ["NX-01", "NCC-1701", "NCC-74656", "NCC-1701-D"], answerIndex: 0, explanation: "The Enterprise in ENT is NX-01."),
        .init(id: 86, category: "ENT", difficulty: .easy, prompt: "Who is Enterprise NX-01’s Vulcan science officer?", choices: ["T'Pol", "Spock", "Tuvok", "Valeris"], answerIndex: 0, explanation: "T’Pol is the Vulcan science officer on NX-01."),
        .init(id: 87, category: "ENT", difficulty: .easy, prompt: "Who is Enterprise NX-01’s chief engineer?", choices: ["Charles 'Trip' Tucker III", "Geordi La Forge", "Montgomery Scott", "Miles O'Brien"], answerIndex: 0, explanation: "Trip Tucker is the chief engineer."),
        .init(id: 88, category: "ENT", difficulty: .easy, prompt: "What species is Dr. Phlox?", choices: ["Denobulan", "Vulcan", "Human", "Trill"], answerIndex: 0, explanation: "Phlox is Denobulan."),
        .init(id: 89, category: "ENT", difficulty: .easy, prompt: "What is the name of Archer’s dog?", choices: ["Porthos", "Spot", "Morn", "Targ"], answerIndex: 0, explanation: "Porthos is Archer’s beloved beagle."),
        .init(id: 90, category: "ENT", difficulty: .medium, prompt: "Which Andorian commander becomes an important ally to Archer?", choices: ["Shran", "Gowron", "Dukat", "Martok"], answerIndex: 0, explanation: "Commander Shran is a key Andorian ally."),
        .init(id: 91, category: "ENT", difficulty: .medium, prompt: "Which group attacked Earth and became central to Season 3 of ENT?", choices: ["The Xindi", "The Borg", "The Dominion", "The Ferengi"], answerIndex: 0, explanation: "The Xindi arc drives ENT Season 3."),
        .init(id: 92, category: "ENT", difficulty: .hard, prompt: "What is the name of the temporal agent who recruits Archer during the Temporal Cold War?", choices: ["Daniels", "Garak", "Zimmerman", "Daystrom"], answerIndex: 0, explanation: "Agent Daniels guides Archer in the Temporal Cold War storyline."),

        // MARK: - Films / General (93–100)

        .init(id: 93, category: "FILMS", difficulty: .easy, prompt: "Who is the main antagonist in Star Trek II: The Wrath of Khan?", choices: ["Khan Noonien Singh", "Shinzon", "General Chang", "V'Ger"], answerIndex: 0, explanation: "Khan is the central villain in Star Trek II."),
        .init(id: 94, category: "FILMS", difficulty: .easy, prompt: "Which Star Trek film involves saving humpback whales by traveling to the 20th century?", choices: ["Star Trek IV: The Voyage Home", "Star Trek: First Contact", "Star Trek: Insurrection", "Star Trek: Nemesis"], answerIndex: 0, explanation: "The whale rescue is the plot of Star Trek IV."),
        .init(id: 95, category: "FILMS", difficulty: .medium, prompt: "In Star Trek: First Contact, which historical figure makes the first warp flight?", choices: ["Zefram Cochrane", "Richard Daystrom", "Noonien Soong", "Hikaru Sulu"], answerIndex: 0, explanation: "Cochrane pilots humanity’s first warp flight."),
        .init(id: 96, category: "FILMS", difficulty: .easy, prompt: "Which villainous group does Picard fight in Star Trek: First Contact?", choices: ["The Borg", "The Dominion", "The Cardassians", "The Ferengi"], answerIndex: 0, explanation: "First Contact centers on a Borg attack."),
        .init(id: 97, category: "GENERAL", difficulty: .easy, prompt: "What device on many starships can create food and everyday objects on demand?", choices: ["Replicator", "Transporter", "Holodeck", "Deflector dish"], answerIndex: 0, explanation: "Replicators can synthesize a wide range of items."),
        .init(id: 98, category: "GENERAL", difficulty: .easy, prompt: "What is the name of the Starfleet training institution?", choices: ["Starfleet Academy", "Federation College", "Vulcan Science Directorate", "Daystrom Institute"], answerIndex: 0, explanation: "Officers train at Starfleet Academy."),
        .init(id: 99, category: "GENERAL", difficulty: .medium, prompt: "What does the Vulcan concept 'IDIC' stand for?", choices: ["Infinite Diversity in Infinite Combinations", "Interstellar Defense in Crisis", "Integrated Diplomacy in Conflict", "Intelligence Directorate in Command"], answerIndex: 0, explanation: "IDIC is a core Vulcan philosophy phrase."),
        .init(id: 100, category: "FILMS", difficulty: .medium, prompt: "What is the Kobayashi Maru test designed to be?", choices: ["A no-win scenario", "A test of piloting speed", "A medical triage exam", "A diplomacy simulation with a guaranteed peaceful solution"], answerIndex: 0, explanation: "It’s famous as a no-win training scenario."),

        // MARK: - TNG (101–115)

        .init(id: 101, category: "TNG", difficulty: .medium, prompt: "What is the name of the android child Data creates in TNG?", choices: ["Lal", "Soji", "Dahj", "B-4"], answerIndex: 0, explanation: "Data’s daughter is Lal."),
        .init(id: 102, category: "TNG", difficulty: .easy, prompt: "What is the name of the Enterprise-D’s lounge located on Deck 10?", choices: ["Ten Forward", "Quark's", "The Observation Deck", "The Ready Room"], answerIndex: 0, explanation: "Ten Forward is the famous lounge on the Enterprise-D."),
        .init(id: 103, category: "TNG", difficulty: .easy, prompt: "Who is the bartender often found in Ten Forward?", choices: ["Guinan", "Neelix", "Quark", "Chapel"], answerIndex: 0, explanation: "Guinan is a key confidant and bartender in Ten Forward."),
        .init(id: 104, category: "TNG", difficulty: .medium, prompt: "Guinan is a member of which species?", choices: ["El-Aurian", "Betazoid", "Trill", "Bajoran"], answerIndex: 0, explanation: "Guinan is an El-Aurian."),
        .init(id: 105, category: "TNG", difficulty: .hard, prompt: "What is the name of the tar-like entity that kills Tasha Yar?", choices: ["Armus", "Nagilum", "Q", "Lore"], answerIndex: 0, explanation: "Armus is the malevolent entity from 'Skin of Evil'."),
        .init(id: 106, category: "TNG", difficulty: .medium, prompt: "What is the name of Captain Picard’s brother?", choices: ["Robert", "Jean", "René", "Louis"], answerIndex: 0, explanation: "Picard’s brother is Robert Picard."),
        .init(id: 107, category: "TNG", difficulty: .easy, prompt: "What is Data’s Starfleet rank for most of TNG?", choices: ["Lieutenant Commander", "Commander", "Lieutenant", "Captain"], answerIndex: 0, explanation: "Data typically holds the rank of Lieutenant Commander."),
        .init(id: 108, category: "TNG", difficulty: .easy, prompt: "Geordi La Forge’s VISOR is best described as what?", choices: ["A device that enables him to see by translating multiple spectra", "A medical tricorder", "A portable force field", "A cloaking device"], answerIndex: 0, explanation: "Geordi’s VISOR converts various spectra into usable visual input."),
        .init(id: 109, category: "TNG", difficulty: .medium, prompt: "Which doctor temporarily replaces Beverly Crusher as CMO early in TNG?", choices: ["Katherine Pulaski", "Christine Chapel", "Julian Bashir", "Leonard McCoy"], answerIndex: 0, explanation: "Dr. Katherine Pulaski serves as CMO in Season 2."),
        .init(id: 110, category: "TNG", difficulty: .easy, prompt: "What is the name of Deanna Troi’s homeworld?", choices: ["Betazed", "Vulcan", "Bajor", "Andoria"], answerIndex: 0, explanation: "Troi’s Betazoid heritage is tied to Betazed."),
        .init(id: 111, category: "TNG", difficulty: .medium, prompt: "In 'Chain of Command', how many lights does Gul Madred insist there are?", choices: ["Four", "Three", "Five", "Six"], answerIndex: 0, explanation: "The interrogation centers on the claim: “There are four lights.”"),
        .init(id: 112, category: "TNG", difficulty: .medium, prompt: "What is the name of Riker’s transporter-created duplicate?", choices: ["Thomas Riker", "Will Riker", "Brad Riker", "Jack Riker"], answerIndex: 0, explanation: "Thomas Riker is the duplicate created by a transporter accident."),
        .init(id: 113, category: "TNG", difficulty: .medium, prompt: "What is the name of the Borg drone who regains individuality in 'I, Borg'?", choices: ["Hugh", "Icheb", "One", "Lore"], answerIndex: 0, explanation: "Hugh is the liberated drone who befriends the Enterprise crew."),
        .init(id: 114, category: "TNG", difficulty: .medium, prompt: "Which holodeck character becomes self-aware and challenges Data and Picard in TNG?", choices: ["Professor Moriarty", "Sherlock Holmes", "Captain Proton", "Vic Fontaine"], answerIndex: 0, explanation: "Moriarty becomes a sentient holodeck character."),
        .init(id: 115, category: "TNG", difficulty: .medium, prompt: "Gul Madred is a member of which species?", choices: ["Cardassian", "Romulan", "Klingon", "Ferengi"], answerIndex: 0, explanation: "Madred is a Cardassian interrogator."),

        // MARK: - DS9 (116–130)

        .init(id: 116, category: "DS9", difficulty: .easy, prompt: "What is the name of Benjamin Sisko’s son?", choices: ["Jake Sisko", "Wesley Crusher", "Alexander Rozhenko", "Harry Kim"], answerIndex: 0, explanation: "Jake is Sisko’s son and a central DS9 character."),
        .init(id: 117, category: "DS9", difficulty: .easy, prompt: "Which Ferengi becomes the first of his species to join Starfleet?", choices: ["Nog", "Quark", "Rom", "Brunt"], answerIndex: 0, explanation: "Nog joins Starfleet in DS9."),
        .init(id: 118, category: "DS9", difficulty: .easy, prompt: "What is the name of Quark’s brother?", choices: ["Rom", "Nog", "Brunt", "Zek"], answerIndex: 0, explanation: "Rom is Quark’s brother (and Nog’s father)."),
        .init(id: 119, category: "DS9", difficulty: .medium, prompt: "Quark’s mother is commonly known by what name?", choices: ["Ishka", "Laris", "Winn", "Pel"], answerIndex: 0, explanation: "Ishka is also nicknamed “Moogie.”"),
        .init(id: 120, category: "DS9", difficulty: .easy, prompt: "What is the primary currency used by Ferengi commerce?", choices: ["Gold-pressed latinum", "Federation credits", "Darsek", "GPL bars of dilithium"], answerIndex: 0, explanation: "Ferengi trade is built around gold-pressed latinum."),
        .init(id: 121, category: "DS9", difficulty: .easy, prompt: "Who is the Cardassian leader strongly associated with Terok Nor/DS9’s past occupation?", choices: ["Gul Dukat", "Garak", "Damar", "Gul Madred"], answerIndex: 0, explanation: "Gul Dukat is central to the occupation-era history."),
        .init(id: 122, category: "DS9", difficulty: .medium, prompt: "Which Klingon eventually becomes Chancellor by the end of DS9?", choices: ["Martok", "Gowron", "Kor", "Chang"], answerIndex: 0, explanation: "Martok becomes Chancellor."),
        .init(id: 123, category: "DS9", difficulty: .easy, prompt: "Odo regenerates by resting in what iconic container?", choices: ["A bucket", "A stasis pod", "A replicator unit", "A holosuite"], answerIndex: 0, explanation: "Odo often rests in a bucket to regenerate."),
        .init(id: 124, category: "DS9", difficulty: .medium, prompt: "Sisko is famously a fan of what real-world sport?", choices: ["Baseball", "Soccer", "Hockey", "Basketball"], answerIndex: 0, explanation: "Sisko’s baseball love is a recurring DS9 detail."),
        .init(id: 125, category: "DS9", difficulty: .medium, prompt: "The DS9 episode featuring a holosuite baseball game names Sisko’s team what?", choices: ["The Niners", "The Crushers", "The Defiants", "The Prophets"], answerIndex: 0, explanation: "Sisko’s team is called the Niners."),
        .init(id: 126, category: "DS9", difficulty: .medium, prompt: "Bajor’s sacred artifacts that grant visions are called what?", choices: ["Orbs of the Prophets", "Time Crystals", "The Nexus Stones", "Katra Shards"], answerIndex: 0, explanation: "Bajorans revere the Orbs of the Prophets."),
        .init(id: 127, category: "DS9", difficulty: .easy, prompt: "Kira Nerys holds what rank for much of DS9?", choices: ["Major", "Captain", "Lieutenant Commander", "Admiral"], answerIndex: 0, explanation: "Kira is often addressed as Major Kira."),
        .init(id: 128, category: "DS9", difficulty: .medium, prompt: "What addictive substance do the Jem'Hadar require to survive?", choices: ["Ketracel-white", "Dilithium", "Trellium-D", "Red matter"], answerIndex: 0, explanation: "Jem’Hadar are dependent on ketracel-white."),
        .init(id: 129, category: "DS9", difficulty: .medium, prompt: "What is the name of Cardassia’s intelligence agency?", choices: ["Obsidian Order", "Tal Shiar", "Section 31", "Vulcan High Command"], answerIndex: 0, explanation: "The Obsidian Order is Cardassian intelligence."),
        .init(id: 130, category: "DS9", difficulty: .medium, prompt: "What is the name of the Romulan intelligence agency?", choices: ["Tal Shiar", "Obsidian Order", "Section 31", "The Q Continuum"], answerIndex: 0, explanation: "The Tal Shiar is Romulan intelligence."),

        // MARK: - VOY (131–145)

        .init(id: 131, category: "VOY", difficulty: .medium, prompt: "Who is the creator of the Voyager EMH program?", choices: ["Lewis Zimmerman", "Noonien Soong", "Richard Daystrom", "Zefram Cochrane"], answerIndex: 0, explanation: "Zimmerman designs the EMH system."),
        .init(id: 132, category: "VOY", difficulty: .easy, prompt: "What is the name of the entity responsible for pulling Voyager to the Delta Quadrant?", choices: ["The Caretaker", "Q", "The Guardian of Forever", "The Traveler"], answerIndex: 0, explanation: "The Caretaker’s actions strand Voyager far from home."),
        .init(id: 133, category: "VOY", difficulty: .easy, prompt: "Chakotay’s crew at the start of Voyager belongs to which rebel group?", choices: ["The Maquis", "The Dominion", "The Obsidian Order", "The Tal Shiar"], answerIndex: 0, explanation: "Chakotay leads a Maquis ship before joining Voyager."),
        .init(id: 134, category: "VOY", difficulty: .medium, prompt: "What device allows the Doctor to leave sickbay and move around the ship freely?", choices: ["A mobile emitter", "A tricorder", "A neural transponder", "A deflector dish upgrade"], answerIndex: 0, explanation: "The mobile emitter lets the Doctor operate outside sickbay."),
        .init(id: 135, category: "VOY", difficulty: .hard, prompt: "The Doctor’s mobile emitter originates from which century?", choices: ["29th century", "24th century", "22nd century", "31st century"], answerIndex: 0, explanation: "It comes from future time-travel technology."),
        .init(id: 136, category: "VOY", difficulty: .medium, prompt: "Which former Borg child joins Voyager’s crew?", choices: ["Icheb", "Hugh", "Lore", "Saru"], answerIndex: 0, explanation: "Icheb is one of the Borg children who joins the crew."),
        .init(id: 137, category: "VOY", difficulty: .medium, prompt: "What is the name of the shared dream-like refuge some Borg drones experience?", choices: ["Unimatrix Zero", "The Nexus", "Fluidic Space", "The Celestial Temple"], answerIndex: 0, explanation: "Unimatrix Zero is a hidden sanctuary for some drones."),
        .init(id: 138, category: "VOY", difficulty: .hard, prompt: "Voyager experiments with which high-speed travel method that uses a special corridor-like flow?", choices: ["Quantum slipstream", "Spore drive", "Transwarp beaming", "Hyperdrive"], answerIndex: 0, explanation: "Voyager briefly tests quantum slipstream technology."),
        .init(id: 139, category: "VOY", difficulty: .medium, prompt: "Which species hunts Voyager’s crew and turns them into holodeck prey?", choices: ["Hirogen", "Kazon", "Breen", "Cardassians"], answerIndex: 0, explanation: "The Hirogen are famed hunters."),
        .init(id: 140, category: "VOY", difficulty: .medium, prompt: "In the episode 'Drone', what single-word name is given to the new Borg created aboard Voyager?", choices: ["One", "Hugh", "Seven", "Zero"], answerIndex: 0, explanation: "The rapidly maturing drone is named One."),
        .init(id: 141, category: "VOY", difficulty: .medium, prompt: "Tom Paris’s black-and-white holodeck hero is named what?", choices: ["Captain Proton", "Professor Moriarty", "Dixon Hill", "Vic Fontaine"], answerIndex: 0, explanation: "Captain Proton is Paris’s retro holodeck adventure persona."),
        .init(id: 142, category: "VOY", difficulty: .easy, prompt: "What is the name of Voyager’s morale officer and cook?", choices: ["Neelix", "Quark", "Guinan", "Rom"], answerIndex: 0, explanation: "Neelix fills the role of cook and morale officer."),
        .init(id: 143, category: "VOY", difficulty: .easy, prompt: "What is the registry number of the USS Voyager?", choices: ["NCC-74656", "NCC-1701", "NCC-1701-D", "NCC-1031"], answerIndex: 0, explanation: "Voyager’s registry is NCC-74656."),
        .init(id: 144, category: "VOY", difficulty: .medium, prompt: "Voyager’s EMH is also known as which model designation?", choices: ["EMH Mark I", "EMH Mark IV", "EMH Mark IX", "EMH Mark X"], answerIndex: 0, explanation: "The Doctor begins as an EMH Mark I."),
        .init(id: 145, category: "VOY", difficulty: .easy, prompt: "Which omnipotent being from TNG also appears on Voyager?", choices: ["Q", "Sarek", "Gowron", "Dukat"], answerIndex: 0, explanation: "Q appears in multiple series, including Voyager."),

        // MARK: - ENT (146–155)

        .init(id: 146, category: "ENT", difficulty: .easy, prompt: "Who is Enterprise NX-01’s tactical/armory officer?", choices: ["Malcolm Reed", "Hoshi Sato", "Travis Mayweather", "Daniels"], answerIndex: 0, explanation: "Malcolm Reed serves as the armory officer."),
        .init(id: 147, category: "ENT", difficulty: .easy, prompt: "Who is Enterprise NX-01’s communications officer?", choices: ["Hoshi Sato", "Beverly Crusher", "Kira Nerys", "Ezri Dax"], answerIndex: 0, explanation: "Hoshi Sato is NX-01’s communications officer."),
        .init(id: 148, category: "ENT", difficulty: .easy, prompt: "Who is Enterprise NX-01’s helmsman?", choices: ["Travis Mayweather", "Tom Paris", "Hikaru Sulu", "Geordi La Forge"], answerIndex: 0, explanation: "Travis Mayweather pilots NX-01."),
        .init(id: 149, category: "ENT", difficulty: .easy, prompt: "What breed is Archer’s dog Porthos?", choices: ["Beagle", "German Shepherd", "Golden Retriever", "Corgi"], answerIndex: 0, explanation: "Porthos is a beagle."),
        .init(id: 150, category: "ENT", difficulty: .medium, prompt: "In Starfleet registries, what does the 'NX' prefix typically indicate?", choices: ["Experimental/prototype", "Medical vessel", "Cargo freighter", "Diplomatic cruiser"], answerIndex: 0, explanation: "NX designations often mark experimental craft."),
        .init(id: 151, category: "ENT", difficulty: .medium, prompt: "What is the name of the dangerous region of space central to ENT Season 3?", choices: ["The Delphic Expanse", "The Badlands", "The Gamma Rift", "Fluidic Space"], answerIndex: 0, explanation: "The Xindi arc centers on the Delphic Expanse."),
        .init(id: 152, category: "ENT", difficulty: .easy, prompt: "Shran is a member of which species?", choices: ["Andorian", "Vulcan", "Klingon", "Ferengi"], answerIndex: 0, explanation: "Shran is an Andorian commander."),
        .init(id: 153, category: "ENT", difficulty: .medium, prompt: "Which species is linked to the Temporal Cold War as part of a secretive cabal early in ENT?", choices: ["Suliban", "Bajoran", "Trill", "Betazoid"], answerIndex: 0, explanation: "The Suliban Cabal is tied to the Temporal Cold War."),
        .init(id: 154, category: "ENT", difficulty: .easy, prompt: "What is the nickname of Enterprise NX-01’s chief engineer Charles Tucker III?", choices: ["Trip", "Bones", "Scotty", "Pips"], answerIndex: 0, explanation: "Charles Tucker III is commonly called Trip."),
        .init(id: 155, category: "ENT", difficulty: .easy, prompt: "Enterprise NX-01 is commonly referred to as the first human ship to achieve what warp capability?", choices: ["Warp 5", "Warp 9", "Warp 1", "Transwarp"], answerIndex: 0, explanation: "NX-01 is humanity’s Warp 5-capable starship."),

        // MARK: - TAS (156–160)

        .init(id: 156, category: "TAS", difficulty: .easy, prompt: "Star Trek: The Animated Series is commonly abbreviated as what?", choices: ["TAS", "TNS", "STV", "TNG"], answerIndex: 0, explanation: "The Animated Series is often shortened to TAS."),
        .init(id: 157, category: "TAS", difficulty: .medium, prompt: "Which three-armed officer serves aboard the Enterprise in The Animated Series?", choices: ["Arex", "Shran", "Damar", "Brunt"], answerIndex: 0, explanation: "Arex is a notable TAS bridge officer."),
        .init(id: 158, category: "TAS", difficulty: .medium, prompt: "M'Ress (from TAS) is best known as an officer of which species?", choices: ["Caitian", "Kelpien", "Trill", "Bajoran"], answerIndex: 0, explanation: "M’Ress is a Caitian officer."),
        .init(id: 159, category: "TAS", difficulty: .easy, prompt: "Which starship is the primary setting of The Animated Series?", choices: ["USS Enterprise", "USS Defiant", "USS Voyager", "USS Cerritos"], answerIndex: 0, explanation: "TAS continues adventures aboard the USS Enterprise."),
        .init(id: 160, category: "TAS", difficulty: .easy, prompt: "Who remains the Enterprise’s captain in The Animated Series?", choices: ["James T. Kirk", "Jean-Luc Picard", "Benjamin Sisko", "Kathryn Janeway"], answerIndex: 0, explanation: "Kirk remains captain during TAS."),

        // MARK: - Kelvin Timeline (161–170)

        .init(id: 161, category: "KELVIN", difficulty: .easy, prompt: "In Star Trek (2009), who is the Romulan captain seeking revenge?", choices: ["Nero", "Dukat", "Gowron", "Chang"], answerIndex: 0, explanation: "Nero is the main antagonist of the 2009 film."),
        .init(id: 162, category: "KELVIN", difficulty: .medium, prompt: "What is the name of Nero’s ship in Star Trek (2009)?", choices: ["Narada", "Defiant", "Protostar", "Relativity"], answerIndex: 0, explanation: "Nero commands the Narada."),
        .init(id: 163, category: "KELVIN", difficulty: .medium, prompt: "What substance is used to create a black hole in Star Trek (2009)?", choices: ["Red matter", "Dilithium", "Ketracel-white", "Trellium-D"], answerIndex: 0, explanation: "Red matter triggers the black hole effect."),
        .init(id: 164, category: "KELVIN", difficulty: .easy, prompt: "Which planet is destroyed in Star Trek (2009)?", choices: ["Vulcan", "Bajor", "Andoria", "Betazed"], answerIndex: 0, explanation: "Vulcan is destroyed in the 2009 film."),
        .init(id: 165, category: "KELVIN", difficulty: .easy, prompt: "By the end of Star Trek (2009), who becomes captain of the USS Enterprise?", choices: ["James T. Kirk", "Christopher Pike", "Spock", "Montgomery Scott"], answerIndex: 0, explanation: "Kirk becomes captain at the end of the film."),
        .init(id: 166, category: "KELVIN", difficulty: .medium, prompt: "What is the name of the massive dreadnought starship built in Star Trek Into Darkness?", choices: ["USS Vengeance", "USS Excelsior", "USS Titan", "USS Cerritos"], answerIndex: 0, explanation: "The dreadnought is the USS Vengeance."),
        .init(id: 167, category: "KELVIN", difficulty: .medium, prompt: "Which infamous augment is revealed as the key villain in Star Trek Into Darkness?", choices: ["Khan Noonien Singh", "Shinzon", "Soran", "V'Ger"], answerIndex: 0, explanation: "The film’s villain is revealed as Khan."),
        .init(id: 168, category: "KELVIN", difficulty: .medium, prompt: "What is the name of the enormous space station-city featured in Star Trek Beyond?", choices: ["Starbase Yorktown", "Deep Space Nine", "Spacedock", "Terok Nor"], answerIndex: 0, explanation: "Starbase Yorktown is featured prominently in Beyond."),
        .init(id: 169, category: "KELVIN", difficulty: .easy, prompt: "Who is the chief engineer of the Enterprise in the Kelvin timeline films?", choices: ["Montgomery 'Scotty' Scott", "Geordi La Forge", "B'Elanna Torres", "Miles O'Brien"], answerIndex: 0, explanation: "Scotty serves as chief engineer."),
        .init(id: 170, category: "KELVIN", difficulty: .easy, prompt: "In Star Trek Beyond, what is the name of the skilled alien ally who joins Kirk’s team?", choices: ["Jaylah", "Laris", "Tendi", "Gwyn"], answerIndex: 0, explanation: "Jaylah helps Kirk and the crew survive on the planet."),

        // MARK: - Discovery (171–180)

        .init(id: 171, category: "DIS", difficulty: .easy, prompt: "Who is the central protagonist of Star Trek: Discovery?", choices: ["Michael Burnham", "Seven of Nine", "Ezri Dax", "T'Pol"], answerIndex: 0, explanation: "Discovery follows Michael Burnham."),
        .init(id: 172, category: "DIS", difficulty: .medium, prompt: "What is the registry number of the USS Discovery?", choices: ["NCC-1031", "NCC-1701", "NCC-74656", "NX-01"], answerIndex: 0, explanation: "Discovery’s registry is NCC-1031."),
        .init(id: 173, category: "DIS", difficulty: .easy, prompt: "Discovery’s experimental faster-than-light system is known as what?", choices: ["Spore drive", "Quantum slipstream", "Transwarp beaming", "Hyperdrive"], answerIndex: 0, explanation: "The Spore drive is Discovery’s signature technology."),
        .init(id: 174, category: "DIS", difficulty: .medium, prompt: "The Spore drive navigates using what interdimensional ecosystem?", choices: ["The mycelial network", "Fluidic space", "The Nexus", "Subspace tunnels"], answerIndex: 0, explanation: "It travels through the mycelial network."),
        .init(id: 175, category: "DIS", difficulty: .medium, prompt: "Which officer is closely associated with the Spore drive as an expert mycologist?", choices: ["Paul Stamets", "Julian Bashir", "Noonien Soong", "Malcolm Reed"], answerIndex: 0, explanation: "Stamets is the specialist tied to Spore drive operations."),
        .init(id: 176, category: "DIS", difficulty: .easy, prompt: "Saru is a member of which species?", choices: ["Kelpien", "Vulcan", "Andorian", "Trill"], answerIndex: 0, explanation: "Saru is a Kelpien."),
        .init(id: 177, category: "DIS", difficulty: .medium, prompt: "What is Saru’s homeworld called?", choices: ["Kaminar", "Vulcan", "Betazed", "Bajor"], answerIndex: 0, explanation: "Saru is from Kaminar."),
        .init(id: 178, category: "DIS", difficulty: .medium, prompt: "Michael Burnham was raised in part by which famous Vulcan diplomat?", choices: ["Sarek", "Syrran", "Spock", "Tuvok"], answerIndex: 0, explanation: "Sarek becomes Burnham’s foster father."),
        .init(id: 179, category: "DIS", difficulty: .easy, prompt: "Captain Christopher Pike is most closely associated with commanding which starship?", choices: ["USS Enterprise", "USS Voyager", "USS Defiant", "USS Cerritos"], answerIndex: 0, explanation: "Pike is a key captain of the USS Enterprise."),
        .init(id: 180, category: "DIS", difficulty: .medium, prompt: "Philippa Georgiou is revealed to hold what title in the Mirror Universe?", choices: ["Emperor", "Chancellor", "Kai", "Grand Nagus"], answerIndex: 0, explanation: "In the Mirror Universe, Georgiou is Emperor."),

        // MARK: - Picard (181–188)

        .init(id: 181, category: "PIC", difficulty: .easy, prompt: "Star Trek: Picard centers on which retired Starfleet captain?", choices: ["Jean-Luc Picard", "James T. Kirk", "Benjamin Sisko", "Jonathan Archer"], answerIndex: 0, explanation: "The series follows Jean-Luc Picard later in life."),
        .init(id: 182, category: "PIC", difficulty: .easy, prompt: "What is the name of Picard’s dog in Star Trek: Picard?", choices: ["Number One", "Spot", "Porthos", "Grudge"], answerIndex: 0, explanation: "Picard’s dog is named Number One."),
        .init(id: 183, category: "PIC", difficulty: .easy, prompt: "Picard’s home is a vineyard known as what?", choices: ["Château Picard", "Ten Forward", "Starbase Yorktown", "The Daystrom Institute"], answerIndex: 0, explanation: "Picard lives at Château Picard."),
        .init(id: 184, category: "PIC", difficulty: .easy, prompt: "What is the name of the ship Picard travels on in Season 1?", choices: ["La Sirena", "Protostar", "Narada", "Defiant"], answerIndex: 0, explanation: "Picard journeys aboard La Sirena."),
        .init(id: 185, category: "PIC", difficulty: .medium, prompt: "Who is the captain/pilot of La Sirena?", choices: ["Cristóbal Rios", "William Riker", "Hikaru Sulu", "Geordi La Forge"], answerIndex: 0, explanation: "Rios is the ship’s captain and pilot."),
        .init(id: 186, category: "PIC", difficulty: .medium, prompt: "Which android character is central to the mystery in Picard Season 1?", choices: ["Soji Asha", "T'Pol", "Kes", "Kira Nerys"], answerIndex: 0, explanation: "Soji is central to Season 1’s story."),
        .init(id: 187, category: "PIC", difficulty: .medium, prompt: "The reclaimed Borg cube in Picard is commonly referred to as what?", choices: ["The Artifact", "Unimatrix Zero", "Terok Nor", "The Nexus"], answerIndex: 0, explanation: "The reclaimed cube is known as the Artifact."),
        .init(id: 188, category: "PIC", difficulty: .medium, prompt: "Seven of Nine is associated with which group helping defend the vulnerable in Picard?", choices: ["Fenris Rangers", "Obsidian Order", "Tal Shiar", "The Xindi"], answerIndex: 0, explanation: "Seven works with the Fenris Rangers."),

        // MARK: - Strange New Worlds (189–196)

        .init(id: 189, category: "SNW", difficulty: .easy, prompt: "Who is the captain of the USS Enterprise in Star Trek: Strange New Worlds?", choices: ["Christopher Pike", "James T. Kirk", "Jean-Luc Picard", "Benjamin Sisko"], answerIndex: 0, explanation: "Strange New Worlds features Captain Pike."),
        .init(id: 190, category: "SNW", difficulty: .medium, prompt: "Enterprise’s first officer 'Number One' is also known as who?", choices: ["Una Chin-Riley", "Erica Ortegas", "Christine Chapel", "La'an Noonien-Singh"], answerIndex: 0, explanation: "Number One is Una Chin-Riley."),
        .init(id: 191, category: "SNW", difficulty: .medium, prompt: "Who serves as the Enterprise’s chief medical officer in Strange New Worlds?", choices: ["Joseph M'Benga", "Leonard McCoy", "Julian Bashir", "Beverly Crusher"], answerIndex: 0, explanation: "Dr. M’Benga is the Enterprise CMO in SNW."),
        .init(id: 192, category: "SNW", difficulty: .easy, prompt: "Christine Chapel is primarily known for serving in what role?", choices: ["Nurse", "Chief engineer", "Security chief", "Helmsman"], answerIndex: 0, explanation: "Chapel is a nurse in SNW."),
        .init(id: 193, category: "SNW", difficulty: .easy, prompt: "Erica Ortegas serves the Enterprise primarily in what role?", choices: ["Helmsman/pilot", "Chief medical officer", "Ship’s counselor", "Bartender"], answerIndex: 0, explanation: "Ortegas pilots the Enterprise."),
        .init(id: 194, category: "SNW", difficulty: .medium, prompt: "La'an Noonien-Singh serves primarily in what area aboard the Enterprise?", choices: ["Security", "Engineering", "Medical", "Diplomacy"], answerIndex: 0, explanation: "La’an is a key security officer."),
        .init(id: 195, category: "SNW", difficulty: .medium, prompt: "Who is the Enterprise’s chief engineer early in Strange New Worlds?", choices: ["Hemmer", "Scotty", "O'Brien", "Trip Tucker"], answerIndex: 0, explanation: "Hemmer leads engineering."),
        .init(id: 196, category: "SNW", difficulty: .hard, prompt: "Hemmer is a member of which Andorian subspecies?", choices: ["Aenar", "Vorta", "Ocampa", "El-Aurian"], answerIndex: 0, explanation: "Hemmer is an Aenar (an Andorian subspecies)."),

        // MARK: - Lower Decks / Prodigy (197–200)

        .init(id: 197, category: "LD", difficulty: .easy, prompt: "What is the name of the Starfleet ship featured in Star Trek: Lower Decks?", choices: ["USS Cerritos", "USS Discovery", "USS Voyager", "USS Defiant"], answerIndex: 0, explanation: "Lower Decks follows the USS Cerritos."),
        .init(id: 198, category: "LD", difficulty: .medium, prompt: "The USS Cerritos is what class of starship?", choices: ["California-class", "Galaxy-class", "Intrepid-class", "Constitution-class"], answerIndex: 0, explanation: "Cerritos is a California-class ship."),
        .init(id: 199, category: "LD", difficulty: .easy, prompt: "Which Lower Decks ensign is known for being a rule-following, ambitious officer?", choices: ["Brad Boimler", "Beckett Mariner", "D'Vana Tendi", "Sam Rutherford"], answerIndex: 0, explanation: "Boimler is famously by-the-book."),
        .init(id: 200, category: "PRO", difficulty: .easy, prompt: "In Star Trek: Prodigy, what is the name of the experimental Starfleet ship the kids find?", choices: ["USS Protostar", "USS Cerritos", "USS Vengeance", "USS Narada"], answerIndex: 0, explanation: "Prodigy centers on the USS Protostar."),
    ]

    /// Returns a randomized quiz subset (no duplicates), capped to available question count.
    public static func randomQuiz(count: Int) -> [TLTriviaQuestion] {
        let n = max(0, min(count, allQuestions.count))
        return Array(allQuestions.shuffled().prefix(n))
    }

    /// Quick filter helpers
    public static func questions(category: String) -> [TLTriviaQuestion] {
        allQuestions.filter { $0.category.caseInsensitiveCompare(category) == .orderedSame }
    }

    public static func questions(difficulty: TLTriviaQuestion.Difficulty) -> [TLTriviaQuestion] {
        allQuestions.filter { $0.difficulty == difficulty }
    }
}

#if DEBUG
private enum _TLTriviaBankValidation {
    static func validate() {
        assert(TLStarTrekTriviaBank.allQuestions.count == 200, "Expected exactly 200 questions.")
        for q in TLStarTrekTriviaBank.allQuestions {
            assert(q.choices.count >= 2, "Question \(q.id) has too few choices.")
            assert(q.choices.indices.contains(q.answerIndex), "Question \(q.id) has invalid answerIndex.")
        }
    }
}
#endif
