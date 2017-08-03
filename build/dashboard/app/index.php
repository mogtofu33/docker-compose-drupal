<?php
require_once __DIR__.'/vendor/autoload.php';

use Dashboard\App;
$app = new App();

// Handle POST/GET requests.
if (isset($_REQUEST['action']) && isset($_REQUEST['id'])) {
  echo $app->processAction($_REQUEST['action'], $_REQUEST['id'], $_REQUEST);
  exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Drupal Docker Compose - Dev stack</title>
</head>
<body>
  <!-- Page Content -->
  <div class="container-fluid">

    <div class="row">
      <div class="col-md-12">
        <h4>
          <a href="https://github.com/Mogtofu33/docker-compose-drupal">Drupal Docker Compose</a>
          <small>Docker full stack for simple Drupal dev.</small>
        </h4>
        <p>
          <a type="button" class="btn btn-xs btn-primary" aria-label="Left Align" href="https://github.com/Mogtofu33/docker-compose-drupal">
            <span class="glyphicon glyphicon-home" aria-hidden="true"></span> Project homepage
          </a>
          <a type="button" class="btn btn-xs btn-info" aria-label="Left Align" href="https://github.com/Mogtofu33/docker-compose-drupal/blob/master/README.md">
            <span class="glyphicon glyphicon-book" aria-hidden="true"></span> Documentation
          </a>
          <a type="button" class="btn btn-xs btn-warning" aria-label="Left Align" href="https://github.com/Mogtofu33/docker-compose-drupal/issues">
            <span class="glyphicon glyphicon-send" aria-hidden="true"></span> Bug report
          </a>
        </p>
      </div>
    </div>

    <div class="alert alert-success alert-dismissible fade in" role="alert" id="message" style="display:none;">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">×</span></button>
      <div class="message"></div>
    </div>

    <div class="row">
      <div class="col-md-7">
        <section class="panel panel-default">
          <div class="panel-heading">Your sites</div>
          <table class="table table-condensed table-hover">
            <thead>
              <tr>
                <th>Source</th>
                <th>Document Root</th>
            </thead>
            <tbody>
              <?php foreach ($app->vars['folders'] AS $folder): ?>
                <tr>
                  <td><a href="http://<?php print $app->vars['apache']['full'] . '/' . $folder; ?>"><?php print ucfirst($folder); ?></a></td>
                  <td><code><?php print str_replace('./', '', $app->vars['dashboard']['root']) . '/' . $folder; ?></code></td>
                </tr>
              <?php endforeach; ?>
            </tbody>
          </table>
        </section>
        <section class="panel panel-default">
          <div class="panel-heading">Containers running</div>
          <table class="table table-condensed table-hover">
            <thead>
              <tr>
                <th></th>
                <th>Port(s)<br><small>(Internal | Public)</small></th>
                <th>Container name</th>
                <th>Container IP</th>
                <th>Details</th>
                <th>Actions</th>
            </thead>
            <tbody>
            <?php foreach ($app->containers AS $container): ?>
              <tr class="<?php print $container['id']; ?>">
                <th><?php print $container['service']; ?></th>
                <td>
                  <table>
                  <?php foreach ($container['ports'] AS $port): ?>
                  <tr>
                    <td>
                      <?php print $port['private']; if (isset($port['public'])): print ' > ' . $port['public'];  endif; ?>
                    </td>
                  </tr>
                  <?php endforeach; ?>
                  </table>
                </td>
                <td><code class="copy"><?php print $container['name']; ?></code></td>
                <td><code class="copy"><?php print $container['ip']; ?></code></td>
                <td>
                  <button type="button" class="btn btn-default btn-xs" data-toggle="modal" data-target="#myModal" data-action="logs" data-container="<?php print $container['id']; ?>">Logs</button>
                  <button type="button" class="btn btn-default btn-xs" data-toggle="modal" data-target="#myModal" data-action="top" data-container="<?php print $container['id']; ?>">Top</button>
                </td>
                <td>
                  <?php if ($container['state_raw'] == 'running'): ?>
                 <button type="button" data-loading-text="Restarting..." class="btn btn-primary btn-xs action" autocomplete="off" data-container="<?php print $container['id'] ?>" data-action="restart">
                  Restart
                 </button>
                <?php endif; ?>
                </td>
              </tr>
            <?php endforeach; ?>
          </table>
        </section>

        <section class="panel panel-default">
          <div class="panel-heading">Services</div>
          <table class="table table-condensed table-hover">
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
                      <table>
                      <?php foreach ($container['ports'] AS $port): ?>
                        <?php if (isset($port['public'])): ?>
                          <tr><td><a href="http://<?php print $app->vars['dashboard']['host'] . ':' . $port['public']; ?>">http://<?php print $app->vars['dashboard']['host'] . ':' . $port['public']; ?></a></td></tr>
                        <?php endif; ?>
                      <?php endforeach; ?>
                      </table>
                    <?php else: ?>
                    Container only
                    <?php endif; ?>
                  </td>
                  <td>
                    <table>
                    <?php foreach ($container['ports'] AS $port): ?>
                      <tr><td><?php print $service . ':' . $port['private']; ?></td></tr>
                    <?php endforeach; ?>
                    </table>
                    </td>
                </tr>
              <?php endif; ?>
            <?php endforeach; ?>
            </tbody>
          </table>
        </section>

      </div>

      <div class="col-md-5">

        <section class="panel panel-default">
          <div class="panel-heading">Development tools</div>
          <table class="table table-condensed table-hover">
            <?php foreach ($app->vars['tools'] AS $tool): ?>
              <tr>
                <th><?php print str_replace('.php', '', ucfirst($tool)); ?></th>
                <td class="text-center">
                  <a href="http://<?php print $app->vars['dashboard']['tools'] . $tool; ?>" class="btn btn-info btn-xs" role="button">Access</a>
                </td>
              </tr>
            <?php endforeach; ?>
          </table>
        </section>

        <?php foreach ($app->containers AS $service => $container): ?>
        <?php if (in_array($service, array_keys($app::$db_services))): ?>
        <section class="panel panel-default">
          <div class="panel-heading"><strong><?php print ucfirst($service); ?></strong> connection information</div>
          <table class="table table-condensed table-hover">
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
            <?php foreach ($app->vars['db_services_env'][$service] AS $env => $value): ?>
            </tr>
              <?php if (getenv($env)): ?>
                <tr>
                  <th><?php print $env; ?></th>
                  <td><code class="copy"><?php print $value; ?></code></td>
                </tr>
              <?php endif; ?>
            <?php endforeach; ?>
          </table>
          <div class="panel-footer">
            <a href="http://<?php print $app->vars['dashboard']['tools'] . 'adminer.php'; ?>?server=<?php print $service; ?>&username=<?php print $app->vars['db_services_env'][$service]['username']; ?>&db=<?php print $app->vars['db_services_env'][$service]['db']; ?>" class="btn btn-info btn-xs" role="button">Adminer connection</a>
          </div>
        </section>
        <?php endif; ?>
        <?php endforeach; ?>
        <section class="panel panel-default">
          <div class="panel-heading">PHP information</div>
          <table class="table table-condensed table-hover">
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
                <?php if ($label == 'Opcache' || $label == 'Xdebug'): ?>
                  <?php print $value; ?>
                <?php else: ?>
                <code><?php print $value; ?></code>
              <?php endif; ?>
              </td>
              </tr>
            <?php endforeach; ?>
          </table>
          <div class="panel-footer">
            <small><a href="/tools/phpinfo.php">View more details in the server's phpinfo() report</a>.</small>
          </div>
        </section>

      </div>
    </div>
    <hr>
    <!-- Footer -->
    <footer>
        <div class="row">
            <div class="col-lg-12">
              <?php if (!empty($_SERVER['SERVER_SIGNATURE'])) print $_SERVER['SERVER_SIGNATURE']; ?> <a type="button" class="btn btn-xs btn-info" href="/server-status">Server status</a> <a type="button" class="btn btn-xs btn-info" href="/server-info">server info</a>
            </div>
        </div>
    </footer>
  </div>
  <!-- /.container -->

  <!-- Modal -->
  <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
    <div class="modal-dialog modal-lg" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
          <h4 class="modal-title" id="myModalLabel"></h4>
        </div>
        <div class="modal-body"><pre style="max-height:500px;overflow-y:scroll;"></pre></div>
        <div class="modal-footer">
          <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
          <button type="button" data-loading-text="Refreshing..." class="btn btn-primary refresh" autocomplete="off"><span class="glyphicon glyphicon-refresh" aria-hidden="true"></span> Refresh</button>
        </div>
      </div>
    </div>
  </div>
  <!-- /.Modal -->

  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
  <!-- jQuery -->
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>
  <script src="https://cdn.jsdelivr.net/clipboard.js/1.6.1/clipboard.min.js"></script>
  <!-- Bootstrap -->
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>

  <!-- Custom script -->
  <script src="js/app.js"></script>
</body>
</html>
