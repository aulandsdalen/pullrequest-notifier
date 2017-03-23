$('.save-button').click(function(){
	$(this).hide();
	$('.loader').show();
	var $inputs = $('#edit-form :input');
	var values = {};
	$inputs.each(function(){
		values[this.name] = $(this).val();
	});
	console.log(JSON.stringify(values));	
	$.post('/update-student', JSON.stringify(values)).done(function(data){
		var response = $.parseJSON(data)
		console.log(response["status"]);
		if(response["status"]) {
			$('.loader').hide();
			$('.btn-container').append("<div class='alert alert-success'><strong>Saved</strong></div>")
		}
		else {
			$('.loader').hide();
			$('.btn-container').append("<div class='alert alert-danger'><strong>Error: </strong>" + response['reason'] + "</div>");
		}
	});
});