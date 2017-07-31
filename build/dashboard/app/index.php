<?php
require_once __DIR__.'/src/app.php';
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

    <?php if ($message): ?>
      <div class="alert alert-<?php print $message['type']; ?> alert-dismissible fade in" role="alert"> <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">×</span></button><?php print $message['text']; ?></div>
    <?php endif; ?>

    <div class="row">
      <div class="col-md-7">
        <section class="panel panel-default">
          <div class="panel-heading">Containers</div>
          <table class="table table-condensed table-hover">
            <thead>
              <tr>
                <th></th>
                <th>Port(s)<br><small>(Internal | Public)</small></th>
                <th>Container name</th>
                <th>Status</th>
                <th>Details</th>
                <th>Actions</th>
            </thead>
            <tbody>
            <?php foreach ($containers_list AS $container): ?>
              <tr class="<?php print $container['id']; ?>">
                <th><?php print $container['service']; ?></th>
                <td>
                  <table>
                  <?php foreach ($container['ports'] AS $port): ?>
                  <tr>
                    <td>
                      <?php print $port[0]; if (isset($port[1])): print ' | ' . $port[1];  endif; ?>
                    </td>
                  </tr>
                  <?php endforeach; ?>
                  </table>
                </td>
                <td><code class="copy"><?php print $container['name']; ?></code></td>
                <td><?php print $container['state']; ?></td>
                <td>
                  <button type="button" class="btn btn-default btn-xs" data-toggle="modal" data-target="#myModal" data-action="log" data-container="<?php print $container['id']; ?>">Logs</button>
                  <button type="button" class="btn btn-default btn-xs" data-toggle="modal" data-target="#myModal" data-action="top" data-container="<?php print $container['id']; ?>">Top</button>
                </td>
                <td>
                  <?php if ($container['state'] == 'Running'): ?>
                  <form method="post">
                  <input type="hidden" name="id" value="<?php print $container['id'] ?>">
                  <input type="hidden" name="action" value="restart">
                  <input type="submit" class="btn btn-info btn-xs" value="Restart">
                 </form>
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
            <?php foreach ($containers_list AS $service): ?>
              <?php if (!in_array($service['service'], $services_to_hide)): ?>
                <tr class="<?php print $service['id']; ?>">
                  <th><?php print $service['service']; ?></th>
                  <td>
                    <?php if ($service['is_public']): ?>
                      <table>
                      <?php foreach ($service['ports'] AS $port): ?>
                        <?php if (isset($port[1])): ?>
                          <tr><td><a href="http://<?php print $host . ':' . $port[1]; ?>">http://<?php print $host . ':' . $port[1]; ?></a></td></tr>
                        <?php endif; ?>
                      <?php endforeach; ?>
                      </table>
                    <?php else: ?>
                    Container only
                    <?php endif; ?>
                  </td>
                  <td>
                    <table>
                    <?php foreach ($service['ports'] AS $port): ?>
                      <tr><td><?php print $service['service_raw'] . ':' . $port[0]; ?></td></tr>
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
            <?php foreach ($tools AS $tool): ?>
              <tr>
                <th><?php print ucfirst($tool); ?></th>
                <td class="text-center">
                  <a href="http://<?php print $dashboard_host . '/TOOLS/' . $tool; ?>" class="btn btn-info btn-xs" role="button">Access</a>
                </td>
              </tr>
            <?php endforeach; ?>
          </table>
        </section>

        <section class="panel panel-default">
          <div class="panel-heading">Your sites</div>
          <table class="table table-condensed table-hover">
            <thead>
              <tr>
                <th>Source</th>
                <th>Document Root</th>
            </thead>
            <tbody>
              <?php foreach ($folders AS $folder): ?>
                <tr>
                  <td><a href="http://<?php print $web_host . '/' . $folder; ?>"><?php print ucfirst($folder); ?></a></td>
                  <td><code><?php print str_replace('./', '', $host_root) . '/' . $folder; ?></code></td>
                </tr>
              <?php endforeach; ?>
            </tbody>
          </table>
        </section>

        <section class="mysql panel panel-default">
          <div class="panel-heading">MySQL connection information</div>
          <table class="table table-condensed table-hover">
            <tr>
              <th>MySQL Hostname</th>
              <td><code>mysql</code></td>
            </tr>
            <tr>
              <th>MySQL Port</th>
              <td><code class="copy">3306</code></td>
            </tr>
            <tr>
              <th>MySQL Database</th>
              <td><code class="copy"><?php print getenv('MYSQL_DATABASE'); ?></code></td>
            </tr>
            <tr>
              <th>MySQL Username</th>
              <td><code class="copy"><?php print getenv('MYSQL_USER'); ?></code></td>
            </tr>
            <tr>
              <th>MySQL Password</th>
              <td><code class="copy"><?php print getenv('MYSQL_PASSWORD'); ?></code></td>
            </tr>
            <tr>
              <th>MySQL ROOT Password</th>
              <td><code class="copy"><?php print getenv('MYSQL_ROOT_PASSWORD'); ?></code></td>
            </tr>
          </table>
          <?php if (in_array('adminer.php', $tools)): ?>
          <div class="panel-footer">
            <a href="http://<?php print $dashboard_host . '/TOOLS/adminer.php'; ?>?server=mysql&username=<?php print getenv('MYSQL_USER'); ?>&db=<?php print getenv('MYSQL_DATABASE'); ?>" class="btn btn-info btn-xs" role="button">Adminer connection</a>
          </div>
          <?php endif; ?>
        </section>

        <section class="pgsql panel panel-default">
          <div class="panel-heading">PostgreSQL connection information</div>
          <table class="table table-condensed table-hover">
            <tr>
              <th>PostgreSQL Hostname</th>
              <td><code class="copy">pgsql</code></td>
            </tr>
            <tr>
              <th>PostgreSQL Port</th>
              <td><code class="copy">3306</code></td>
            </tr>
            <tr>
              <th>PostgreSQL Database</th>
              <td><code class="copy"><?php print getenv('POSTGRES_DB'); ?></code></td>
            </tr>
            <tr>
              <th>PostgreSQL Username</th>
              <td><code class="copy"><?php print getenv('POSTGRES_USER'); ?></code></td>
            </tr>
            <tr>
              <th>PostgreSQL Password</th>
              <td><code class="copy"><?php print getenv('POSTGRES_PASSWORD'); ?></code></td>
            </tr>
          </table>
          <?php if (in_array('adminer.php', $tools)): ?>
          <div class="panel-footer">
            <a href="http://<?php print $dashboard_host . '/TOOLS/adminer.php'; ?>?pgsql=pgsql&username=<?php print getenv('POSTGRES_USER'); ?>&db=<?php print getenv('POSTGRES_DB'); ?>" class="btn btn-info btn-xs" role="button">Adminer connection</a>
          </div>
          <?php endif; ?>
        </section>

        <section class="panel panel-default">
          <div class="panel-heading">PHP information</div>
          <table class="table table-condensed table-hover">
            <tr>
              <th>PHP Version</th>
              <td><code><?php print phpversion(); ?></code></td>
            </tr>
            <tr>
              <th>PHP ini</th>
              <td>
                <code>config/php<?php print getenv('PHP_VERSION'); ?>/conf.d/zz-php.ini</code>
                <small>Need to restart stack if edited.</small>
              </td>
            </tr>
            <tr>
              <th>Webserver</th>
              <td><code><?php (!empty($_SERVER['SERVER_SOFTWARE']))  ? print $_SERVER['SERVER_SOFTWARE'] : print ucfirst($server); ?></cite></td>
            </tr>
            <tr>
              <th>Memory limit</th>
              <td><code><?php print ini_get('memory_limit'); ?></code></td>
            </tr>
            <tr>
              <th>Max execution time</th>
              <td><code><?php print ini_get('max_execution_time'); ?></code></td>
            </tr>
            <tr>
              <th>XDebug</th>
              <td>
              <?php if (function_exists('xdebug_start_code_coverage')): ?>
                <div><span class="label label-success">Enabled</span></div>
              <?php else: ?>
                <div><span class="label label-warning">Disabled</span></div>
              <?php endif; ?>
              </td>
            </tr>
          </table>
          <div class="panel-footer">
            <small><a href="/TOOLS/phpinfo.php">View more details in the server's phpinfo() report</a>.</small>
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
    <hr>
  </div>
  <!-- /.container -->

  <!-- Modal -->
  <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
    <div class="modal-dialog modal-lg" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
          <!-- <h4 class="modal-title" id="myModalLabel"></h4> -->
        </div>
        <div class="modal-body"></div>
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
  <!-- <script src="js/app.js"></script> -->

  <script>
  jQuery( document ).ready(function( $ ) {
    // Clipboard copy js.
    $('.copy').each(function(i, e) {
      $(this).after('<button class="copy btn btn-xs" data-clipboard-text="' + $(this).text() + '"><span class="glyphicon glyphicon-copy"></span></button>');
    });
    var clipboard = new Clipboard('.copy');
    clipboard.on('success', function(e) {
      $(e.trigger).after(' <span class="label label-default">Copied!</span>');
      $(e.trigger).next('.label').delay(2000).fadeOut('slow');
      e.clearSelection();
    });

    // Modal actions.
    $('#myModal').on('show.bs.modal', function (event) {
      var button = $(event.relatedTarget);
      var id = button.data('container');
      var action = button.data('action');

      var modal = $(this);
      if (action == 'log' || action == 'top') {
        modal.find('.modal-title').text('Logs for ' + id);
        $.get("/index.php", { action : action, id: id }, function(data) {
          if (data != "null") {
            result = $.parseJSON(data);
            modal.find('.modal-body').html('<pre>' + result + '</pre>');
          }
        });
      }
    });

    // Other actions.
    $('.action').on('click', function () {
      var id = $(this).data('container');
      var action = $(this).data('action');
      $.get("/index.php", { action : action, id: id }, function(data) {
        if (data != "null") {
          result = $.parseJSON(data);
        }
      });
    });

  });
  </script>
</body>

</html>
