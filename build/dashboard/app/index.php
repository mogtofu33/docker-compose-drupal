<?php
require_once __DIR__.'/vendor/autoload.php';

use Dashboard\App;
$app = new App();

// Handle POST/GET requests.
if (isset($_REQUEST['action']) && isset($_REQUEST['id'])) {
  echo $app->processAction($_REQUEST['action'], $_REQUEST['id']);
  exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <title>Drupal Docker Compose - Dev stack</title>
    <!-- https://getbootstrap.com/docs/4.0/content/typography/#responsive-typography -->
    <style>
    html {
      font-size: 14px;
    }
    @include media-breakpoint-up(sm) {
      html {
        font-size: 16px;
      }
    }
    @include media-breakpoint-up(md) {
      html {
        font-size: 20px;
      }
    }
    @include media-breakpoint-up(lg) {
      html {
        font-size: 28px;
      }
    }
    /* Fix Bs4 default a flashy color. */
    body a {
      color: #337ab7;
    }
    body .btn-link {
      color: #5f6a75;
    }
    /* Extend modal width */
    .modal-lg {
      max-width: 80% !important;
    }
    </style>
</head>
<body>
  <!-- Page Content -->
  <div class="container-fluid my-3">

    <div class="row">
      <div class="col">
        <h4>
          <a href="https://github.com/Mogtofu33/docker-compose-drupal" target="_blank"><span class="badge badge-info">Drupal Docker Compose</span></a>
          <small>Docker full stack for simple Drupal dev.</small>
        </h4>
        <p>
          <a class="btn btn-sm btn-outline-info" href="https://github.com/Mogtofu33/docker-compose-drupal" target="_blank" role="button">
            <span class="octicon octicon-home" aria-hidden="true"></span> Project homepage
          </a>
          <a class="btn btn-sm btn-outline-secondary" href="https://github.com/Mogtofu33/docker-compose-drupal/blob/master/README.md" target="_blank">
            <span class="octicon octicon-book" aria-hidden="true"></span> Documentation
          </a>
          <a class="btn btn-sm btn-outline-warning" href="https://github.com/Mogtofu33/docker-compose-drupal/issues" target="_blank">
            <span class="octicon octicon-bug" aria-hidden="true"></span> Bug report
          </a>
        </p>
      </div>
    </div>

    <div class="alert alert-success alert-dismissible fade in" role="alert" id="message" style="display:none;">
      <button class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">×</span></button>
      <div class="message"></div>
    </div>

    <div class="row">
      <div class="col">
        <section class="card mb-3">
          <div class="card-header">Your sites</div>
          <table class="table table-hover table-sm table-responsive mb-0">
            <thead>
              <tr>
                <th>Host</th>
                <th>Document Root</th>
            </thead>
            <tbody>
              <?php foreach ($app->vars['dashboard']['root'] as $host): ?>
                <tr>
                  <td>
                    <a target="_blank" href="<?php ($host['port'] == '443') ? print 'https:' : ''; ?>//<?php print $host['host']; ?>">
                      <?php print $host['host'] . ':' . $host['port']; ?>
                    </a>
                  </td>
                  <td>
                    <code><?php print $host['root']; ?></code>
                  </td>
                </tr>
              <?php endforeach; ?>
            </tbody>
          </table>

        </section>

        <section class="card mb-3">
          <div class="card-header">Containers running</div>
          <table class="table table-hover table-sm table-responsive mb-0">
            <thead>
              <tr>
                <th></th>
                <th>Port(s)<br><small>(Internal | Public)</small></th>
                <th>Container name</th>
                <th>Container IP</th>
                <th>Details</th>
                <!-- <th>Actions</th> -->
            </thead>
            <tbody>
            <?php foreach ($app->containers AS $container): ?>
              <tr class="<?php print $container['id']; ?>">
                <th><?php print $container['service']; ?></th>
                <td>
                  <ul class="list-unstyled mb-0">
                  <?php foreach ($container['ports'] AS $port): ?>
                    <li><?php print $port['private']; if (isset($port['public'])): print ' > ' . $port['public'];  endif; ?></li>
                  <?php endforeach; ?>
                </ul>
                </td>
                <td><code class="copy"><?php print $container['name']; ?></code></td>
                <td><code class="copy"><?php print $container['ip']; ?></code></td>
                <td>
                  <button class="btn btn-outline-dark btn-sm" data-toggle="modal" data-target="#myModal" data-action="logs" data-container="<?php print $container['id']; ?>">Logs</button>
                  <button class="btn btn-outline-dark btn-sm" data-toggle="modal" data-target="#myModal" data-action="top" data-container="<?php print $container['id']; ?>">Top</button>
                </td>
                <!-- <td>
                  <?php if ($container['state_raw'] == 'running'): ?>
                 <button data-loading-text="Restarting..." class="btn btn-primary btn-sm action" autocomplete="off" data-container="<?php print $container['id'] ?>" data-action="restart">
                  Restart
                 </button>
                <?php endif; ?>
                </td> -->
              </tr>
            <?php endforeach; ?>
          </table>

          <div class="card-footer">
            <div class="form-inline">
            <label for="exec">Quick command on</label>
            <select class="form-control form-control-sm ml-1" name="id" id="exec">
              <option value="_none">- Select -</option>
              <?php foreach ($app->containers as $c): ?>
              <option value="<?php print $c['id']; ?>"><?php print $c['service']; ?></option>
              <?php endforeach; ?>
            </select>
            </div>
            <div id="terminal" style="display:none;">
              <small>Command are send through <code>docker exec -t</code> as <strong>ROOT</strong>, you can only run direct and simple commands from the system root.<br>For more complex commands you can type in a local terminal: <code class="copy">docker exec -it CONTAINER_NAME /bin/sh</code></small>
              <div class="body"></div>
            </div>
          </div>
        </section>

        <section class="card mb-3">
          <div class="card-header">Services</div>
          <table class="table table-hover table-sm table-responsive mb-0">
            <thead>
              <tr>
                <th></th>
                <th>Host access</th>
                <th>Container access</th>
            </thead>
            <tbody>
            <?php foreach ($app->containers AS $service => $container): ?>
              <?php if (!in_array($service, $app::$services_to_hide)): ?>
                <tr class="<?php print $container['id']; ?>">
                  <th><?php print $container['service']; ?></th>
                  <td>
                    <?php if ($container['is_public']): ?>
                      <ul class="list-unstyled mb-0">
                      <?php foreach ($container['ports'] AS $port): ?>
                        <?php if (isset($port['public']) && $port['mode']): ?>
                          <li><a target="_blank" href="<?php print $port['mode']; ?>://<?php print $app->vars['dashboard']['host'] . ':' . $port['public']; ?>"><?php print $port['mode']; ?>://<?php print $app->vars['dashboard']['host'] . ':' . $port['public']; ?></a></li>
                        <?php endif; ?>
                      <?php endforeach; ?>
                      </ul>
                    <?php endif; ?>
                  </td>
                  <td>
                    <ul class="list-unstyled mb-0">
                    <?php foreach ($container['ports'] AS $port): ?>
                      <li><?php print $service . ':' . $port['private']; ?></li>
                    <?php endforeach; ?>
                    </ul>
                  </td>
                </tr>
              <?php endif; ?>
            <?php endforeach; ?>
            </tbody>
          </table>
        </section>

      </div>

      <div class="col">

        <section class="card mb-3">
          <div class="card-header">Development tools</div>
          <table class="table table-hover table-sm table-responsive mb-0">
            <?php foreach ($app->vars['tools'] AS $tool): ?>
              <tr>
                <th><?php print str_replace('.php', '', ucfirst($tool)); ?></th>
                <td class="text-center">
                  <a target="_blank" href="http://<?php print $app->vars['dashboard']['tools'] . $tool; ?>" class="btn btn-info btn-sm" role="button">Access</a>
                </td>
              </tr>
            <?php endforeach; ?>
          </table>
        </section>

        <?php foreach ($app->containers AS $service => $container): ?>
        <?php if (in_array($service, array_keys($app::$db_services))): ?>
        <section class="card mb-3">
          <div class="card-header"><strong><?php print ucfirst($service); ?></strong> connection information</div>
          <table class="table table-hover table-sm table-responsive mb-0">
            <tr>
              <th>Hostname</th>
              <td><code><?php print $service; ?></code></td>
            </tr>
            <tr>
              <th>Docker Ip</th>
              <td><code><?php print $container['ip']; ?></code></td>
            </tr>
            <tr>
              <th>Port</th>
              <td><code class="copy"><?php print end($container['ports'])['private']; ?></code></td>
            <?php if (isset($app->vars['db_services_env'][$service])): ?>
            <?php foreach ($app->vars['db_services_env'][$service] AS $env => $value): ?>
            </tr>
              <?php if (getenv($env)): ?>
                <tr>
                  <th><?php print $env; ?></th>
                  <td><code class="copy"><?php print $value; ?></code></td>
                </tr>
              <?php endif; ?>
            <?php endforeach; ?>
            <?php endif; ?>
          </table>
          <div class="card-footer">
            <?php if (isset($app->vars['db_services_env'][$service])): ?>
            <a target="_blank" href="http://<?php print $app->vars['dashboard']['tools'] . 'adminer.php'; ?>?<?php print $service; ?>=<?php print $service; ?>&amp;server=<?php print $service; ?>&amp;username=<?php print $app->vars['db_services_env'][$service]['username']; ?>&db=<?php print $app->vars['db_services_env'][$service]['db']; ?>" class="btn btn-info btn-sm" role="button">Adminer connection</a>
            <?php endif; ?>
          </div>
        </section>
        <?php endif; ?>
        <?php endforeach; ?>
        <section class="card mb-3">
          <div class="card-header">PHP information</div>
          <table class="table table-hover table-sm table-responsive mb-0">
            <tr>
              <th>PHP Version</th>
              <td><code><?php print $app->getPhpVersion(); ?></code></td>
            </tr>
            <tr>
              <th>PHP ini</th>
              <td>
                <code>config/php/php.ini</code>
                <small>Need to restart apache if edited.</small>
              </td>
            </tr>
            <?php $php_info = $app->getPhpInfo(); ?>
            <?php foreach ($php_info AS $label => $value): ?>
              <tr>
                <th><?php print $label; ?></th>
                <td>
                <?php if ($label == 'Opcache' || $label == 'Xdebug' || $label == 'PhpFpm'): ?>
                  <?php print $value; ?>
                <?php else: ?>
                <code><?php print $value; ?></code>
              <?php endif; ?>
              </td>
              </tr>
            <?php endforeach; ?>
          </table>
          <div class="card-footer">
            <small><a target="_blank" href="/tools/phpinfo.php">View more details in the server's phpinfo() report</a>.</small>
          </div>
        </section>

      </div>
    </div>
    <hr>
    <!-- Footer -->
    <footer>
        <div class="row">
            <div class="col">
              <ul class="list-inline">
                <li class="list-inline-item"><?php if (!empty($_SERVER['SERVER_SIGNATURE'])) print $_SERVER['SERVER_SIGNATURE']; ?></li>
                <li class="list-inline-item">
                  <button class="btn btn-sm btn-info" data-toggle="modal" data-target="#myModal" data-action="get" data-url="server-status" data-title="Server status">Server status</button>
                </li>
                <li class="list-inline-item">
                  <button class="btn btn-sm btn-info" data-toggle="modal" data-target="#myModal" data-action="get" data-url="server-info" data-title="Server info">Server info</button>
                </li>
                <li>

                </li>
              </ul>
            </div>
        </div>
    </footer>
    <hr>
  </div>
  <!-- /.container -->

  <!-- Modal -->
  <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-hidden="true">
  <div class="modal-dialog modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"></h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body"></div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
        <button type="button" data-loading-text="Refreshing..." class="btn btn-primary refresh" autocomplete="off"><span class="octicon octicon-sync" aria-hidden="true"></span> Refresh</button>
      </div>
    </div>
  </div>
</div>
  <!-- /.Modal -->

  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/css/bootstrap.min.css" integrity="sha384-/Y6pD6FV/Vv2HJnA6t+vslU6fwYXjCFtcEpHbNJ0lyAFsXTsjBbfaDjzALeQsN6M" crossorigin="anonymous">

  <!-- Octicons -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/octicons/4.4.0/font/octicons.min.css">

  <!-- jQuery -->
  <script
  src="https://code.jquery.com/jquery-3.2.1.min.js"
  integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4="
  crossorigin="anonymous"></script>
  <!-- Bootstrap + Popper-->
  <script
  src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.11.0/umd/popper.min.js"
  integrity="sha384-b/U6ypiBEHpOf/4+1nzFpr53nxSS+GLCkfwBdFNTxtclqqenISfwAzpKaMNFNmj4"
  crossorigin="anonymous"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/js/bootstrap.min.js"
  integrity="sha384-h0AbiXch4ZDo7tp9hKZ4TsHbi047NrKGLO3SEJAg45jXxnGIfYzk4Si90RDIqNm1"
  crossorigin="anonymous"></script>

  <script src="https://cdn.jsdelivr.net/clipboard.js/1.6.1/clipboard.min.js"></script>
  <!-- Bootstrap -->
  <!-- <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script> -->
  <!-- Terminal -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.terminal/1.5.3/js/jquery.terminal.min.js"></script>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/jquery.terminal/1.5.3/css/jquery.terminal.min.css" rel="stylesheet"/>

  <!-- Custom script -->
  <script src="js/app.js"></script>
  <script src="js/unix_formatting.js"></script>
</body>
</html>
