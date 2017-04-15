$(document).ready(function(){
	$('[data-toggle="tooltip"]').tooltip();
	$(".download-button").attr("disabled", true);
	$('textarea').keyup(function(){
		if($('#files-input').val().length > 0) {
			$('.download-button').attr('disabled', false);
		}
		else {
			$('.download-button').attr('disabled', true);
		}
	});
});
$('.download-button').click(function(){
	$(this).hide();
	$('.loader').show();
	var $inputs = $('#bgen-form :input');
	var values = {};
	var output = null;
	$inputs.each(function(){
		values[this.name] = $(this).val();
	});
	values["files"] = values["files"].split("\n");
	values["files"] = values["files"].filter(function(n){
		return n !== "";
	});
	values["flags"] = values["flags"].split(" ");
	values["flags"] = values["flags"].filter(function(n){
		return n !== "";
	});
	output = JSON.stringify(values);
	var dataStream = "data:text/json;charset=utf-8,"+encodeURIComponent(output);
	$('#download-anchor').attr("href", dataStream);
	$('#download-anchor').attr("download", "build.json");
	document.getElementById("download-anchor").click(); /* for some reason, $("#download-anchor").click() won't work here */
	$(this).show();
	$('.loader').hide();	
});
