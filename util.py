import os
from concurrent.futures import ThreadPoolExecutor

CONFIG_PATH = './config'


def multi_accounts_task(fn):
    configs = []
    try:
        for path in os.listdir(CONFIG_PATH):
            configs.append(os.path.join(CONFIG_PATH, path))
    except Exception:
        pass

    if len(configs) == 0:
        print('没有找到配置文件, 请执行应用注册 Action.')
        exit(1)

    futures, pool = [], ThreadPoolExecutor(len(configs))
    for config in configs:
        futures.append(pool.submit(fn, config))

    for future in futures:
        print(f'{future.result()}')
