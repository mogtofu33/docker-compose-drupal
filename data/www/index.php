<?php
  // Variables
  $ip = $_SERVER['SERVER_ADDR'];
  $server = getenv('CONTAINER_NAME');
  $host = getenv('SERVER_NAME');
  $port = getenv('SERVER_PORT');
  $host_root = getenv('HOST_WEB_ROOT');
  $container_root = getenv('DOCUMENT_ROOT');
  if ($port != '80') {
    $web_host = $host . ':' . $port;
  }
  else {
    $web_host = $host;
  }
  // Get tools from folder.
  $tools = array_diff(scandir($container_root . '/TOOLS'), array('..', '.', 'scripts'));
  // Get current folders exept drupal and tools.
  $folders = array_diff(scandir($container_root), array('..', '.', '.htaccess', 'index.php', 'TOOLS'));
  // Define services.
  $services = array(
    'apache' => array('list' => FALSE, 'port' => getenv('APACHE_HOST_HTTP_PORT') . ' | ' . getenv('APACHE_HOST_HTTPS_PORT')),
    'nginx' => array('list' => FALSE, 'port' => getenv('NGINX_HOST_HTTP_PORT') . ' | ' . getenv('NGINX_HOST_HTTPS_PORT')),
    'phpfpm' => array('list' => FALSE, 'port' => '9000'),
    'docker-ui' => array(
      'list' => TRUE,
      'port' => '9001',
      'host_access' => TRUE,
    ),
    'mysql' => array(
      'list' => TRUE,
      'port' => '3306',
      'guest_access' => TRUE,
    ),
    'pgsql' => array(
      'list' => TRUE,
      'port' => '5432',
      'guest_access' => TRUE,
    ),
    'memcache' => array(
      'list' => TRUE,
      'port' => '11211',
      'guest_access' => TRUE,
    ),
    'solr' => array(
      'list' => TRUE,
      'port' => getenv('SOLR_HOST_PORT'),
      'path' => '/solr/drupal',
      'guest_access' => TRUE,
      'host_access' => TRUE,
    ),
    'mailhog' => array(
      'list' => TRUE,
      'port' => getenv('MAILHOG_HOST_PORT'),
      'host_access' => TRUE,
    ),
    'varnish' => array(
      'list' => TRUE,
      'port' => getenv('VARNISH_HOST_PORT'),
    ),
    'ldap' => array(
      'list' => TRUE,
      'port' => getenv('LDAP_HOST_PORT'),
      'extra' => 'Ldap Hostname: <code>http://ldap:389</code><br>
                  login: <code>cn=admin,dc=example,dc=org</code><br>
                  pass: <code>admin</code><br>
                  <a href="https://github.com/osixia/docker-openldap#environment-variables">More ldap info on GitHub project.</a>',
      'guest_access' => TRUE,
      'host_access' => TRUE,
    ),
    'ldapadmin' => array(
      'list' => TRUE,
      'port' => getenv('PHPLDAPADMIN_HOST_PORT'),
      'host_access' => TRUE,
    ),
  );

  // Handle ajax request for ip and hostname.
  if (isset($_REQUEST['get_infos'])) {
    if (isset($services[$_REQUEST['get_infos']])) {
      print json_encode(get_infos($_REQUEST['get_infos'], $services[$_REQUEST['get_infos']]));
    }
    else {
      print null;
    }
    exit;
  }
  function get_infos($id, $service) {
    $ip = gethostbyname($id);
    if ($ip != $id) {
      $hostname = gethostbyaddr($ip);
      $hostname = explode('.', $hostname);
      $hostname = $hostname[0];
      $service += array('ip' => $ip) + array('hostname' => $hostname);
      return $service;
    }
  }
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Drupal Docker Compose Stack</title>
</head>

<body>
  <!-- Page Content -->
  <div class="container-fluid">

    <div class="row">
      <div class="col-md-12">
        <h4>
          <a href="https://github.com/Mogtofu33/docker-compose-drupal">Drupal Docker Compose</a>
          <small>Docker full stack for easy Drupal dev.</small>
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

    <div class="row">
      <div class="col-md-7">

        <section class="panel panel-default">
          <div class="panel-heading">Your sites</div>
          <table class="table table-condensed table-hover">
            <thead>
              <tr>
                <th>Source</th>
                <th>Document Root</th>
                <th>Container document Root</th>
            </thead>
            <tbody>
              <?php foreach ($folders AS $folder): ?>
                <tr>
                  <td><a href="http://<?php print $web_host . '/' . $folder; ?>"><?php print ucfirst($folder); ?></a></td>
                  <td><code><?php print str_replace('./', '', $host_root) . '/' . $folder; ?></code></td>
                  <td><code class="copy"><?php print $container_root . '/' . $folder; ?></code></td>
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
                <th>IP</th>
                <th>Service port</th>
                <th>Container name/id</th>
            </thead>
            <tbody>
            <?php foreach ($services AS $id => $service): ?>
              <tr class="hidden <?php print $id; ?>">
                <th><?php print ucfirst($id); ?></th>
                <td class="ip"></td>
                <td><?php print $service['port']; ?></td>
                <td class="hostname"></td>
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
            <?php foreach ($services AS $id => $service): ?>
              <?php if ($service['list']): ?>
                <tr class="hidden <?php print $id; ?>">
                  <th><?php print ucfirst($id); ?></th>
                  <td>
                    <?php if (isset($service['host_access'])): ?>
                    <a href="http://<?php print $host . ':' . $service['port']; ?>">http://<?php print $host . ':' . $service['port']; ?></a>
                    <?php else: ?>
                    Container only
                    <?php endif; ?>
                  </td>
                  <td>
                    <?php if (isset($service['guest_access'])): ?>
                    <?php print $id . ':' . $service['port']; ?><?php isset($service['path']) ? print $service['path'] : ''; ?>
                    <?php else: ?>
                    Host only
                    <?php endif; ?>
                    </td>
                </tr>
                <?php if (isset($service['extra'])): ?>
                <tr class="hidden <?php print $id; ?>"><td colspan="3"><?php print $service['extra']; ?></td></tr>
                <?php endif; ?>
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
                  <a href="http://<?php print $web_host . '/TOOLS/' . $tool; ?>" class="btn btn-info btn-xs" role="button">Access</a>
                </td>
              </tr>
            <?php endforeach; ?>
          </table>
        </section>

        <section class="mysql hidden panel panel-default">
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
            <a href="http://<?php print $web_host . '/TOOLS/adminer.php'; ?>?server=mysql&username=<?php print getenv('MYSQL_USER'); ?>&db=<?php print getenv('MYSQL_DATABASE'); ?>" class="btn btn-info btn-xs" role="button">Adminer connection</a>
          </div>
          <?php endif; ?>
        </section>

        <section class="pgsql hidden panel panel-default">
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
            <a href="http://<?php print $web_host . '/TOOLS/adminer.php'; ?>?pgsql=pgsql&username=<?php print getenv('POSTGRES_USER'); ?>&db=<?php print getenv('POSTGRES_DB'); ?>" class="btn btn-info btn-xs" role="button">Adminer connection</a>
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
    <div class="row">
      <div class="col-md-12">

        <section class="panel panel-default">
          <div class="panel-heading">Docker usefull commands</div>
          <table class="table table-condensed table-hover">
            <tr>
              <th>See logs</th>
              <td><code class="copy">docker-compose logs</code></td>
            </tr>
            <tr>
              <th>See running containers</th>
              <td><code class="copy">docker-compose ps</code></td>
            </tr>
            <tr>
              <th>Restart containers</th>
              <td><code class="copy">docker-compose restart</code></td>
            </tr>
            <tr>
              <th>Destroy containers</th>
              <td><code class="copy">docker-compose stop && docker-compose down</code></td>
            </tr>
            <tr>
              <th>Bash in the container</th>
              <td><code class="copy">docker exec -it CONTAINER_NAME_OR_ID bash</code></td>
            </tr>
            <tr>
              <th>Shell in third party containers<br><small>Not based on mogtofu33 images, can vary, depend on images.</small></th>
              <td><code class="copy">docker exec -it CONTAINER_NAME_OR_ID sh</code></td>
            </tr>
            <tr>
              <th>Remove your data (Full reset!)</th>
              <td><code class="copy">sudo rm -rf data/database data/logs data/www/drupal</code></td>
            </tr>
          </table>
          <div class="panel-footer"><small><a href="https://docs.docker.com/compose/reference/">More commands on Docker Compose reference page</a>.</small></div>
        </section>

        <section class="panel panel-default">
          <div class="panel-heading">Docker drush/drupal commands</div>
          <table class="table table-condensed table-hover">
            <tr>
              <th>Using Drush with your container</th>
              <td><code>. scripts/start-drush.sh</code></td>
            </tr>
            <tr>
              <th>Quick dl Drupal 7</th>
              <td><code class="copy">drush dl drupal-7 -y --destination=/www --drupal-project-rename</code></td>
            </tr>
            <tr>
              <th>Quick dl Drupal 8</th>
              <td><code class="copy">drush dl drupal -y --destination=/www --drupal-project-rename</code></td>
            </tr>
            <tr>
              <th>Quick install Drupal</th>
              <td><code class="copy">drush si -y --db-url=mysql://drupal:drupal@mysql/drupal --account-name=admin --account-pass=password</code></td>
            </tr>
            <tr>
              <th>When you finish</th>
              <td><code class="copy">. scripts/end-drush.sh</code></td>
            </tr>
          </table>
        </section>

      </div>
    </div>
    <hr>
    <!-- Footer -->
    <footer>
        <div class="row">
            <div class="col-lg-12">
              <?php if (!empty($_SERVER['SERVER_SIGNATURE'])) print $_SERVER['SERVER_SIGNATURE']; ?>
            </div>
        </div>
    </footer>
  </div>
  <!-- /.container -->

  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
  <!-- jQuery -->
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
  <script src="https://cdn.jsdelivr.net/clipboard.js/1.5.10/clipboard.min.js"></script>

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
    // Services async grabber.
    var services = <?php echo json_encode($services); ?>;
    $.each(services, function( index, value ) {
      $.get("/index.php", { get_infos: index }, function(data) {
        if (data != "null") {
          result = $.parseJSON(data);
          $('.' + index).removeClass("hidden");
          $('.' + index + ' .ip').html(result["ip"]);
          $('.' + index + ' .hostname').html('<code class="copy">' + result["hostname"] + '</code><button class="copy btn btn-xs" data-clipboard-text="' + result["hostname"] + '"><span class="glyphicon glyphicon-copy"></span></button>');
        }
      });
    });
  });
  </script>
</body>

</html>
