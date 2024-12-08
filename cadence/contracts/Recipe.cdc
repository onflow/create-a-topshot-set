
import "TopShot"

access(all) contract Recipe {
    // This is a snippet extracting the relevant logic from the TopShot contract for demonstration purposes
    // TopShot Contract Code Above

    // Variable size dictionary of SetData structs
    access(self) var setDatas: {UInt32: SetData}

    // Variable size dictionary of Set resources
    access(self) var sets: @{UInt32: Set}

    // The ID that is used to create Sets. Every time a Set is created
    // setID is assigned to the new set's ID and then is incremented by 1.
    access(all) var nextSetID: UInt32

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

            TopShot.setDatas[self.setID] = SetData(name: name)
        }

        view fun getPlays(): [UInt32] {
            return self.plays
        }

        view fun getRetired(): {UInt32: Bool} {
            return self.retired
        }

        view fun getNumMintedPerPlay(): {UInt32: UInt32} {
            return self.numberMintedPerPlay
        }

        access(all) fun addPlay(playID: UInt32) {
            pre {
                TopShot.playDatas[playID] != nil: "Cannot add the Play to Set: Play doesn't exist."
                !self.locked: "Cannot add the play to the Set after the set has been locked."
                self.numberMintedPerPlay[playID] == nil: "The play has already been added to the set."
            }

            self.plays.append(playID)
            self.retired[playID] = false
            self.numberMintedPerPlay[playID] = 0

            emit PlayAddedToSet(setID: self.setID, playID: playID)
        }

        access(all) fun retirePlay(playID: UInt32) {
            pre {
                self.retired[playID] != nil: "Cannot retire the Play: Play doesn't exist in this set!"
            }

            if !self.retired[playID]! {
                self.retired[playID] = true
                emit PlayRetiredFromSet(setID: self.setID, playID: playID, numMoments: self.numberMintedPerPlay[playID]!)
            }
        }

        access(all) fun lock() {
            if !self.locked {
                self.locked = true
                emit SetLocked(setID: self.setID)
            }
        }

        access(all) fun mintMoment(playID: UInt32): @NFT {
            pre {
                self.retired[playID] != nil: "Cannot mint the moment: This play doesn't exist."
                !self.retired[playID]!: "Cannot mint the moment from this play: This play has been retired."
            }

            let numInPlay = self.numberMintedPerPlay[playID]!
            let newMoment: @NFT <- create NFT(serialNumber: numInPlay + UInt32(1), playID: playID, setID: self.setID)
            self.numberMintedPerPlay[playID] = numInPlay + UInt32(1)
            return <-newMoment
        }
    }

    access(all) resource Admin {

        access(all) fun createSet(name: String): UInt32 {
            var newSet <- create Set(name: name)
            TopShot.nextSetID = TopShot.nextSetID + UInt32(1)

            let newID = newSet.setID
            emit SetCreated(setID: newSet.setID, series: TopShot.currentSeries)
            TopShot.sets[newID] <-! newSet
            return newID
        }
    }
}