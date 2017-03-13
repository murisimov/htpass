# For Nginx + uWSGI

import sys
from os.path import dirname

sys.path.insert(0, dirname(__file__))
sys.path.insert(0, dirname(__file__) + '../')

from htpass_server import app as application

if __name__ == '__main__':
    application.run()
