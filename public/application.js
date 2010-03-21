$(function() {
  $('.upload').load("/new");
  
  $('#add').click(function() {
    div = $('<div class="upload"></div>');
    div.insertAfter('.upload:last').load("/new");
    return(false);
  });
  
  $('#upload_all').click(function() {
    $.each($('form'), function(n, form) {
      $(this).ajaxSubmit({
        success: function(response, status, set) {
          set.html('<p class="success">Upload complete!</p>');
        },
        complete: function(xhr, status) {
          if (status == "error") { alert(xhr.responseText); }
        }
      });
    });
  });
});
