var emailRegex = /^[A-Z0-9._%+-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i;

$.getJSON("/groups.json", function(json){
	$('#group-select').empty();
	$('#group_select').append($('<option>').text("Group"));
	$.each(json, function(i, obj) {
		if (!obj.gid)
			obj.gid = 'nogrp'
		$('#group-select').append($('<option>').text(obj.group_name).attr('value', obj.gid));
	});
});


$(document).ready(function(){
	$('.signup-button').attr('disabled', true);
	$('input').keyup(function(){
		if($('#realname').val().length > 0 && emailRegex.test($('#email').val()) && $('#username').val().length > 0) {
			$('.signup-button').attr('disabled', false);
		}
		else {
			$('.signup-button').attr('disabled', true);
		}
	});
});

$('.signup-button').click(function(){
	$(this).hide();
	$('.loader').show();
	var $inputs = $('#signup-form :input');
	var values = {};
	$inputs.each(function(){
		values[this.name] = $(this).val();
	});
	console.log(JSON.stringify(values));	
	$.post('/signup', JSON.stringify(values)).done(function(data){
		var response = $.parseJSON(data)
		console.log(response["status"]);
		if(response["status"]) {
			$('.loader').hide();
			$('.btn-container').append("<div class='alert alert-success'><strong>Пользователь зарегистрирован</strong></div>")
		}
		else {
			$('.loader').hide();
			$('.btn-container').append("<div class='alert alert-danger'><strong>При регистрации произошла ошибка: </strong>" + response['reason'] + "</div>");
		}
	});
});