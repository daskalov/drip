var multiplexer;
multiplexer = function(comp, fam) {
  return now.render(comp, fam, function(x) {
    return alert(x);
  });
};
$(document).ready(function() {
  return $('#render_button').click(function() {
    return now.render('walls:list', function(ret) {
      return $('#stuff').append(ret);
    });
  });
});