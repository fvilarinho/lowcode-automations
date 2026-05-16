#!/usr/bin/env python3

import psutil

cpu_usage = psutil.cpu_percent(interval=1)

print(f'{cpu_usage}%')
