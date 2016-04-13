$(function(){

    getOpenIdToken()
      .done(function(resp) {
        $.ajax({
          url: 'http://localhost:3000/api/events.json',
          type: 'GET',
          headers: {
            'Authorization': 'Bearer ' + resp.token
          }
        }).done(function(events) {
          $('#calendar').fullCalendar({
            header: {
              left: 'prev,next today',
              center: 'title',
              right: 'month,agendaWeek,agendaDay'
            },
            defaultDate: '2016-01-12',
            eventLimit: true,
            events: events
          });
        })
  });
});


function getOpenIdToken() {
  return $.getJSON('/auth')
}
