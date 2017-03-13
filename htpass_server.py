
import string
from functools import partial
from os import urandom
#from hashlib import md5
#from urllib import quote, quote_plus

from flask import (
    Flask,
    abort,
    #make_response,
    escape,
    flash,
    redirect, render_template,
    request, session,
    url_for,
)
from utils import insights, traceback, crypt, salt


# request.args  -  url encoded parameters
# request.form  -  post data

app = Flask(__name__)
app.secret_key = urandom(24)

# Utils for detailed loggging
insights, traceback = [partial(insights, app), partial(traceback, app)]


@app.route("/login", methods=['GET', 'POST'])
def login(filename='/home/htpass/.htpasswd'):
    kwargs = {
        'type': type,
        'dict': dict,
        'error': None,
        'username': '',
        'password': '',
        'confirmed_password': '',
    }

    if request.method == 'GET':
        return render_template('login.html', **kwargs)

    elif request.method == 'POST':
        # NOTE: update kwargs with POSTed credentials
        kwargs.update({ k: v[0] for k, v in dict(request.form).items() })

        # Extract credentials
        username = kwargs['username']
        password = kwargs['password']
        confirmed_password = kwargs['confirmed_password']

        # TODO: provide all required checks
        # Check for empty fields
        if not username or not password or not confirmed_password:
            kwargs['error'] = "Something is missing"
            return render_template('login.html', **kwargs)

        # Maxlength check
        for item in ['username', 'password', 'confirmed_password']:
            if len(kwargs[item][:33]) > 32:
                kwargs['error'] = (
                    "The %s is too long"
                ) % " ".join(item.split('_'))
                return render_template('login.html', **kwargs)

        # Allowed username symbols check
        allowed_symbols = string.ascii_letters + string.digits + '_'
        for letter in username:
            if letter not in allowed_symbols:
                kwargs['error'] = (
                    "Only ascii symbols, digits and _ - ! "
                    "symbols are allowed for username"
                )
                return render_template('login.html', **kwargs)

        # Password match check
        if password != confirmed_password:
            kwargs['error'] = "Passwords do not match"
            return render_template('login.html', **kwargs)

        # Username length check
        if not 3 <= len(username) <= 12:
            kwargs['error'] = ("Username should be at least 3 "
                               "and no more 12 characters long")
            return render_template('login.html', **kwargs)

        # Password length check
        if not 6 <= len(password) <= 30:
            kwargs['error'] = ("Password should be at least 6 "
                               "and no more 30 characters long")
            return render_template('login.html', **kwargs)

        # Open file in 'a+' mode to create it, if it does not exist yet
        with open(filename, 'a+') as f:

            # Move to the beginning of the file
            f.seek(0, 0)

            # Free username check
            if username in f.read():
                kwargs['error'] = "User already exists"
                return render_template('login.html', **kwargs)

            # Move to the end of the file
            f.seek(0, 2)
            app.logger.info(password)
            f.write(
                "%s:%s\n" % (username, crypt.crypt(password, salt()))
            )

        # Remember this user to show corresponding message
        session['username'] = username

        flash("Thank you for your assistance", "success")
        return redirect(url_for('index'))


@app.route("/")
def index():
    if not session.get('username'):
        return redirect(url_for('login'))

    kwargs = {
        'type': type,
        'dict': dict,
        'name': session['username'],
    }

    return render_template('index.html', **kwargs)


@app.route("/logout")
def logout():
    session.pop('username', None)
    return redirect(url_for('login'))


if __name__ == "__main__":
    app.run()
