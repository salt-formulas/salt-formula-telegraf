=======================
Salt Telegraf formula
=======================

Power your metrics and alerting with a leading open-source monitoring
solution.

Sample pillars
==============

.. code-block:: yaml

  telegraf:
    agent:
      enabled: true
      interval: 15
      round_interval: false
      metric_batch_size: 1000
      metric_buffer_limit: 10000
      collection_jitter: 2
      output:
        prometheus_client:
          bind:
            address: 0.0.0.0
            port: 9126
          engine: prometheus


Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-logrotate/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-logrotate

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
