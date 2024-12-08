import "TopShot"
import "NonFungibleToken"

access(all) contract Recipe {
    // This is a snippet extracting the relevant logic from the TopShot contract for demonstration purposes
    // TopShot Contract Code Above

    // Variable size dictionary of SetData structs
    access(self) var setDatas: {UInt32: SetData}

    // Variable size dictionary of Set resources
    access(self) var sets: @{UInt32: Set}

    // The ID used to create Sets
    access(self) var nextSetID: UInt32

    // Events
    access(all) event PlayAddedToSet(setID: UInt32, playID: UInt32)
    access(all) event PlayRetiredFromSet(setID: UInt32, playID: UInt32, numMoments: UInt32)
    access(all) event SetLocked(setID: UInt32)
    access(all) event SetCreated(setID: UInt32, series: UInt32)

    init() {
        self.setDatas = {}
        self.sets <- {}
        self.nextSetID = 0
    }

    // A Set is a grouping of Plays that have occurred in the real world
    // that make up a related group of collectibles, like sets of baseball
    // or Magic cards. A Play can exist in multiple different sets.
    // 
    // SetData is a struct that is stored in a field of the contract.
    // Anyone can query the constant information
    // about a set by calling various getters located 
    // at the end of the contract. Only the admin has the ability 
    // to modify any data in the private Set resource.
    //
    access(all) struct SetData {

        // Unique ID for the Set
        access(all) let setID: UInt32

        // Name of the Set
        access(all) let name: String

        // Series that this Set belongs to.
        access(all) let series: UInt32

        init(name: String) {
            pre {
                name.length > 0: "New Set name cannot be empty"
            }
            self.setID = TopShot.nextSetID
            self.name = name
            self.series = TopShot.currentSeries
        }
    }

    access(all) resource Set {

        // Unique ID for the set
        access(all) let setID: UInt32

        // Array of plays that are a part of this set.
        access(contract) var plays: [UInt32]

        // Map of Play IDs that Indicates if a Play in this Set can be minted.
        access(contract) var retired: {UInt32: Bool}

        // Indicates if the Set is currently locked.
        access(all) var locked: Bool

        // Mapping of Play IDs that indicates the number of Moments 
        access(contract) var numberMintedPerPlay: {UInt32: UInt32}

        init(name: String) {
            self.setID = TopShot.nextSetID
            self.plays = []
            self.retired = {}
            self.locked = false
            self.numberMintedPerPlay = {}

            TopShot.setDatas[self.setID] = Recipe.SetData(name: name)
        }

        // Get the list of Plays in the Set
        access(all) view fun getPlays(): [UInt32] {
            return self.plays
        }

        // Get the retired status of Plays in the Set
        access(all) view fun getRetired(): {UInt32: Bool} {
            return self.retired
        }

        // Get the number of Moments minted for each Play
        access(all) view fun getNumMintedPerPlay(): {UInt32: UInt32} {
            return self.numberMintedPerPlay
        }

        // Add a Play to the Set
        access(all) fun addPlay(playID: UInt32) {
            pre {
                TopShot.playDatas[playID] != nil: "Cannot add Play: Play doesn't exist."
                !self.locked: "Cannot add Play: Set is locked."
                self.numberMintedPerPlay[playID] == nil: "Play already added."
            }

            self.plays.append(playID)
            self.retired[playID] = false
            self.numberMintedPerPlay[playID] = 0

            emit PlayAddedToSet(setID: self.setID, playID: playID)
        }

        // Retire a Play from the Set
        access(all) fun retirePlay(playID: UInt32) {
            pre {
                self.retired[playID] != nil: "Cannot retire Play: Play doesn't exist in set."
            }

            if !self.retired[playID]! {
                self.retired[playID] = true
                emit PlayRetiredFromSet(
                    setID: self.setID,
                    playID: playID,
                    numMoments: self.numberMintedPerPlay[playID]!
                )
            }
        }

        // Lock the Set to prevent further modifications
        access(all) fun lock() {
            if !self.locked {
                self.locked = true
                emit SetLocked(setID: self.setID)
            }
        }

        // Mint a Moment from a Play in the Set
        access(all) fun mintMoment(playID: UInt32): @NFT {
            pre {
                self.retired[playID] != nil: "Cannot mint: Play doesn't exist."
                !self.retired[playID]!: "Cannot mint: Play retired."
            }

            let numInPlay = self.numberMintedPerPlay[playID]!
            let newMoment: @NFT <- create NFT(
                serialNumber: numInPlay + UInt32(1),
                playID: playID,
                setID: self.setID
            )
            self.numberMintedPerPlay[playID] = numInPlay + UInt32(1)
            return <-newMoment
        }
    }

    // Admin resource to manage the contract
    access(all) resource Admin {

        // Create a new Set
        access(all) fun createSet(name: String): UInt32 {
            var newSet <- create Set(name: name)
            TopShot.nextSetID = TopShot.nextSetID + UInt32(1)

            let newID = newSet.setID
            emit SetCreated(setID: newID, series: TopShot.currentSeries)
            Recipe.sets[newID] <-! newSet
            return newID
        }
    }
}
