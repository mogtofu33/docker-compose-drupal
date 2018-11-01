
$(function() {

  $.getJSON('/blocks', function( data ) {
    $.each(data, function() {
      $("#" + this.name).html(this.html);
    });
  }).done(function( data ) {
    $('.loading').hide();
    // Clipboard.
    $('body').find('.copy').each(function(i, e) {
      $(this).after('<button title="Copy to clipboard" class="copy btn btn-sm btn-link" data-clipboard-text="' + $(this).text().trim() + '"><span class="octicon octicon-clippy"></span></button>');
    });
  });

  $('body').on('click', '.refresh-block', function() {
    var block = $(this).data('block');
    $("#" + block + ' table').html('<div class="lds-ellipsis"><div></div><div></div><div></div><div></div></div>');
    $.getJSON('/block/' + block, function( data ) {
      $("#" + block).html(data.html);
    });
  });

  var clipboard = new Clipboard('.copy');
  clipboard.on('success', function(e) {
    $(e.trigger).after(' <span class="label label-default">Copied!</span>');
    $(e.trigger).next('.label').delay(2000).fadeOut('slow');
    e.clearSelection();
  });

  // Modal actions.
  $('#myModal').on('show.bs.modal', function (event) {
    var $btn = $(event.relatedTarget);
    var $id = $btn.data('container');
    var $name = $btn.data('name');
    var $action = $btn.data('action');
    var modal = $(this);

    // Propagate refresh information.
    modal.find('.refresh').data({'action': $action, 'id': $id});

    modal.find('.modal-body').html('');

    if ($action == 'get') {
      modal.find('.modal-title').text($btn.data('title'));
      modal.find('.modal-body').html(
        '<div class="padding-zero embed-responsive embed-responsive-21by9">' +
        '<iframe id="iframe" class="embed-responsive-item" src="' + $btn.data('url') + '"></iframe>' +
        '</div>'
      );
    }
    else {
      modal.find('.modal-title').text($action + ' ' + $name);
      // Request to endpoint.
      $.getJSON("/api/container/" + $id + "/" + $action, {}, function(response) {
        if (response != "null") {
          modal.find('.modal-title').html(response.message);
          for (var key in response.result) {
            modal.find('.modal-body').append('<label>' + key + '</label><pre>' + response.result[key].join("\r") + '</pre>');
          }
        }
      }).done(function( data ) {
        if ($btn.hasClass('refresh-line')) {
          var $class = $btn.data('class');
          var $path = $btn.data('path');
          $('.' + $class + '.' + $id).html('<tr><td>...</td></tr>');
          $.getJSON("/block/" + $path + "/" + $id, {}, function(response) {
            if (response != "null") {
              $('.' + $class + '.' + $id).replaceWith(response.html);
            }
          });
        }
      });
    }

    modal.find('button.refresh').on('click', function (event) {
      modal.find('.modal-body iframe').html('<h5>Refreshing...</h5>');
      if ($action == 'get') {
        $('#iframe').attr('src', function (i, val) { return val; });
      }
      else {
        $.getJSON("/api/container/" + $id + "/" + $action, {}, function(response) {
          if (response != "null") {
            modal.find('.modal-body').html('');
            for (var key in response.result) {
              modal.find('.modal-body').append('<label>' + key + '</label><pre>' + response.result[key].join("\r") + '</pre>');
            }
          }
        });
      }
    });
  });

  $('#myModal').on('hidden.bs.modal', function (e) {
    var modal = $(this);
    modal.find('button.refresh').off( "click" );
  })

});
