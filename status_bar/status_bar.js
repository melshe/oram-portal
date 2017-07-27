function animateStatus(phase) {
	var newWidth = Math.round((phase / 6) * 90).toString() + "%";
	$("#status_bar").animate({
		width: newWidth
	}, 200, function() {});
	$("#status_text").html("You are currently in phase " + phase.toString());
}