import "TopShot"

transaction {

    let admin: &TopShot.Admin

    prepare(signer: auth(Storage) &Account) {
        // Borrow the Admin resource from the specified storage path
        self.admin = signer.storage.borrow<&TopShot.Admin>(from: /storage/TopShotAdmin)
            ?? panic("Cannot borrow admin resource")
    }

    execute {
        self.admin.createSet(name: "Rookies")
        log("Set created")
    }
}
