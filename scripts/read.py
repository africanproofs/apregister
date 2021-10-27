from brownie import accounts, FlareStakeholderRegister, network, config


def read_register():
    register = FlareStakeholderRegister[-1]
    print(register.getProviders())

def main():
    read_register()