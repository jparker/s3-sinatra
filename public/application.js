$(function() {
  $('#upload_all').click(function() {
    var forms = $('form');
    $.each(forms, function(n, form) {
      $(this).ajaxSubmit();
    });
  });
});
