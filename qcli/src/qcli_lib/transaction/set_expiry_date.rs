use crate::qcli_lib::transaction::{common, Error};
use quibitous_lib::interfaces;
use structopt::StructOpt;

#[derive(StructOpt)]
#[structopt(rename_all = "kebab-case")]
pub struct SetExpiryDate {
    #[structopt(flatten)]
    pub common: common::CommonTransaction,

    /// the slot this transaction should be valid until, for example 3.14
    #[structopt(name = "BLOCKDATE")]
    pub valid_until: interfaces::BlockDate,
}

impl SetExpiryDate {
    pub fn exec(self) -> Result<(), Error> {
        let mut transaction = self.common.load()?;
        transaction.set_expiry_date(self.valid_until)?;
        self.common.store(&transaction)
    }
}
