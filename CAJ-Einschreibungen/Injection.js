function login(username, password) {
    $('#id1').val(username);
    $('input.password').val(password);
    $('#id3').click();
}


function getAllCourses() {
    var courseTRs = document.querySelector('body>table>tbody>tr td:nth-child(2)>table:nth-child(5)>tbody').children;
    // console.log(courseTRs);
    
    var allCourses = [];
    
    for (i = 0; i < courseTRs.length; i++) {
        var courseTbody = courseTRs[i].querySelector("td>table>tbody");
        // console.log(courseTbody);
        
        var course = {};
        course["typ"] = courseTbody.querySelector("tr>td>b").innerHTML;
        course["name"] = courseTbody.querySelector("tr>td>a>span").innerHTML;
        course["ort"] = courseTbody.querySelector("tr:nth-child(2)>td>a>span").innerHTML;
        course["zeit"] = courseTbody.querySelector("tr:nth-child(2)>td>span").innerHTML;
        course["dozent"] = courseTbody.querySelector("tr:nth-child(2)>td:nth-child(2)").innerHTML;
        // console.log(course);
        
        allCourses.push(course);
    }
    
//        console.log(allCourses);
    window.webkit.messageHandlers.courses.postMessage(allCourses);
}