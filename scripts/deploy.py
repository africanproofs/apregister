from brownie import accounts, FlareParticipantRegister, network, config


def deploy_flare_participant_register():
    account = get_accounts()
    register = FlareParticipantRegister.deploy({"from": account})

    # p = register.getParticipant('0x66aB6D9362d4F35596279692F0251Db635165871')

    participants = register.getAllParticipants()

    print(f"The number of participant is {len(participants)}")

    tx = register.register("African Proofs", "https://proofs.africa/participant.json")

    participants = register.getAllParticipants()

    print(f"The number of participant is {len(participants)}")

    participant = register.getParticipant(participants[0])

    print(f"The first participant is {participant}")

    tx = register.register("African Proofs2", "https://www.proofs.africa/participant.json2")

    # participant = register.getParticipant(participants[0])

    updated = register.getParticipant(participants[0])

    print(f"The updated participant is {updated}")

    tx_unregister = register.unregister()

    unregistered = register.getParticipant(participants[0])

    print(f"The unregistered participant is {unregistered}")

    """ prvdrs = register.getProviders()

    print(prvdrs)

    tx = register.register("af", "proofs")
    prvdrs = register.getProviders()

    print(prvdrs) """


def get_accounts():
    if network.show_active() == "development":
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_key"])


def main():
    deploy_flare_participant_register()
