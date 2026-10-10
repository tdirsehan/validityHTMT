import asyncio
from jamovi.server.modules import Modules
async def main():
    modules = Modules.instance()
    await modules.read()
    await modules.install_from_file('/work/artifacts/validityHTMT_0.2.1_linux_R4.1.2.jmo')
    module = modules.get('validityHTMT')
    assert not module.incompatible
    assert module.get('discriminantValidity') is not None
    print('PASS: jamovi module installation', flush=True)
asyncio.run(main())
