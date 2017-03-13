# For Apache2 WSGI

import sys
from os.path import dirname

sys.path.insert(0, dirname(__file__))
sys.path.insert(0, dirname(__file__) + '../')

from htpass_server import app as application

#activate_this = dirname(__file__) + 'env/bin/activate'
#execfile(activate_this, dict(__file__=activate_this))
