"""
cpu watchdog
"""

import logging
import os
import psutil
from flask import Flask, jsonify

logging.basicConfig(level=logging.DEBUG)

PROCNAME = "python2"

app = Flask(__name__)

@app.route("/", methods=['POST'])
def kill():
    """
    kill process
    """

    logging.info("killing process..")
    for proc in psutil.process_iter():
      # check whether the process name matches
        logging.debug('name ' + proc.name())
        logging.debug('id ' + str(proc.pid))
        logging.debug('my id ' + str(os.getpid()))
        if proc.name() == PROCNAME and os.getpid() != proc.pid:
            logging.warning('killing pid ' + str(os.getpid()))
            proc.kill()
    return jsonify(pids=[])

if __name__ == "__main__":
    app.run(debug=False)
