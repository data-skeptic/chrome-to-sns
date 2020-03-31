const url = "https://4buo70od4m.execute-api.us-east-2.amazonaws.com/prod/webhook/chrome"

const data = {"window.location.href": window.location.href}

$.ajax(url, {
    data : JSON.stringify(data),
    contentType : 'application/json',
    type : 'POST',
    success: function () {
        console.log('ack')
    }
});
