import TopShot from 0x01

transaction {

    let admin: &TopShot.Admin

    prepare(signer: auth(Storage, Capabilities) &Account) {
        
        let adminCap = signer.capabilities.storage.borrow<&TopShot.Admin>(/storage/TopShotAdmin)
            ?? panic("Cannot borrow admin resource")

        self.admin = adminCap
    }

    execute {
        self.admin.createSet(name: "Rookies")
        log("Set created")
    }
}
