function animateStatus(phase) {
	var newWidth = Math.round((phase / 10) * 97.5).toString() + "%";
	$("#status_bar").animate({
		width: newWidth,
		easing: "swing"
	}, 500, function() {});
	$("#status_text").html("Phase " + phase.toString() + " out of 10");
}