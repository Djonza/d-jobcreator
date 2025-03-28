window.addEventListener('message', function(event) {
    const data = event.data;
    const container = document.getElementById('job-manager');
    const containerClass = document.querySelector('.container');
    
    if (data.action === 'open') {
        container.classList.remove('hidden');
        document.body.style.display = 'flex';
        setTimeout(() => {
            containerClass.style.opacity = 1;
            containerClass.style.transform = 'scale(1)';
        }, 50);
        showSection("job-list")
    }
    
    if (data.action === 'close') {
        const containerClass = document.querySelector('.container');
        containerClass.style.opacity = 0;
        containerClass.style.transform = 'scale(0.8)';
        setTimeout(() => {
            container.classList.add('hidden');
            document.body.style.display = 'none';
        }, 400); 
    }
    
    if (data.action === 'displayJobs') {
        let jobListDiv = document.getElementById('job-list');
        jobListDiv.innerHTML = '';
    
        let sortedJobs = data.data.sort((a, b) => a.name.localeCompare(b.name));
    
        sortedJobs.forEach(function(job) {
            let p = document.createElement('p');
            p.innerText = `ID: ${job.id} | Name: ${job.name}`;
            jobListDiv.appendChild(p);
        });
    } 
    if (data.action === 'updateJobGrades') {
        renderJobGrades(event.data.grades);
    }   
});


function showSection(sectionId) {
    const sections = document.querySelectorAll('.section');
    document.body.classList.add("lock-scroll");

    sections.forEach(section => {
        if (section.id === sectionId) {
            section.style.opacity = 0;
            section.style.transform = "translateY(20px)"; 
            section.style.display = "block"; 
            setTimeout(() => {
                section.style.opacity = 1;
                section.style.transform = "translateY(0)";
            }, 50);
        } else {
            section.style.opacity = 0;
            section.style.transform = "translateY(-20px)"; 
            setTimeout(() => {
                section.style.display = "none";
            }, 300); 
        }
    });
    setTimeout(() => {
        document.body.classList.remove("lock-scroll");
    }, 500);
}


document.getElementById('closeBtn').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
});

window.addEventListener('message', function(event) {
    if (event.data.type === 'jobGrades') {
        renderJobGrades(event.data.grades);
    }
});


function renderJobGrades(grades) {
    const container = document.getElementById('job-ranks-body');
    container.innerHTML = "";
    grades.forEach(grade => {
        let row = document.createElement('tr');
        row.dataset.jobName = grade.job_name; 
        row.dataset.grade = grade.grade

        row.innerHTML = `
            <td>${grade.grade}</td>
            <td>
                <input type="text" value="${grade.name}" 
                       data-job-name="${grade.job_name}" data-field="name" 
                       class="editable-input name-input"/>
            </td>
            <td>
                <input type="text" value="${grade.label}" 
                       data-job-name="${grade.job_name}" data-field="label" 
                       class="editable-input label-input"/>
            </td>
            <td>
                <input type="number" value="${grade.salary}" 
                       data-job-name="${grade.job_name}" data-field="salary" 
                       class="editable-input salary-input"/>
            </td>
            <td>
              <button class="bin-button" onclick="deleteJobGrade('${grade.job_name}', ${grade.grade}, this)">
  <svg
    class="bin-top"
    viewBox="0 0 39 7"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <line y1="5" x2="39" y2="5" stroke="white" stroke-width="4"></line>
    <line
      x1="12"
      y1="1.5"
      x2="26.0357"
      y2="1.5"
      stroke="white"
      stroke-width="3"
    ></line>
  </svg>
  <svg
    class="bin-bottom"
    viewBox="0 0 33 39"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <mask id="path-1-inside-1_8_19" fill="white">
      <path
        d="M0 0H33V35C33 37.2091 31.2091 39 29 39H4C1.79086 39 0 37.2091 0 35V0Z"
      ></path>
    </mask>
    <path
      d="M0 0H33H0ZM37 35C37 39.4183 33.4183 43 29 43H4C-0.418278 43 -4 39.4183 -4 35H4H29H37ZM4 43C-0.418278 43 -4 39.4183 -4 35V0H4V35V43ZM37 0V35C37 39.4183 33.4183 43 29 43V35V0H37Z"
      fill="white"
      mask="url(#path-1-inside-1_8_19)"
    ></path>
    <path d="M12 6L12 29" stroke="white" stroke-width="4"></path>
    <path d="M21 6V29" stroke="white" stroke-width="4"></path>
  </svg>
</button>
            </td>
        `;

        container.appendChild(row);
    });
}

function deleteJobGrade(jobName, grade, button) {
    const data = {
        job_name: jobName,
        grade: grade
    };

    const row = button.closest('tr');
    row.classList.add('deleting'); 
    setTimeout(() => {
        fetch("https://d-jobcreator/deleteJobGrade", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(data) 
        })
    }, 500); 
}

function fetchUpdatedJobGrades() {
    fetch("https://d-jobcreator/getJobGrades", {  
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    })
    .then(response => response.json())
    .then(grades => {
        renderJobGrades(grades);
    })
    .catch(error => {
        console.error("Failed to fetch updated job grades:", error);
    });
}


function saveJobGrades() {
    const updates = [];
    document.querySelectorAll("#job-ranks-body tr").forEach(row => {
        let jobName = row.dataset.jobName; 
        let grade = row.dataset.grade; 
        if (jobName && grade) {
            const update = {
                job_name: jobName,
                grade: grade,
                name: row.querySelector(".name-input").value,
                label: row.querySelector(".label-input").value,  
                salary: parseInt(row.querySelector(".salary-input").value)
            };
            updates.push(update);
        }
    });
    console.log("📤 Sending updates to server:", updates);
    fetch("https://d-jobcreator/updateJobGrades", {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ data: updates })
    });
}

$(function () {
    fetchJobs(); 

    function fetchJobs() {
        $.post("https://d-jobcreator/getJobsList"); 
    }
    
    window.addEventListener("message", function (event) {
        if (event.data.type === "jobsList") {
            let jobsList = document.getElementById("jobsList");
            jobsList.innerHTML = "";
            let sortedJobs = event.data.jobs.sort((a, b) => a.name.localeCompare(b.name));
            sortedJobs.forEach(job => {
                let jobElement = document.createElement("div");
                jobElement.classList.add("job-item");
                jobElement.innerText = job.name;
                jobElement.addEventListener('click', () => EditJobModal(job.name, job.society, job.id));
                jobsList.appendChild(jobElement);
            });        
        }
    });
});

function openAddJobModal() {
    const jobModal = document.getElementById('jobModal')
    jobModal.style.display = 'flex';
    jobModal.style.opacity = 1;
    jobModal.style.transform = 'scale(0.8)';
    setTimeout(() => {
        jobModal.style.opacity = 1;
        jobModal.style.transform = 'scale(1)';
    }, 50);
  }

  function closeAddJobModal() {
    const jobModal = document.getElementById('jobModal');
    jobModal.style.opacity = 0;
    jobModal.style.transform = 'scale(0.8)';
    setTimeout(() => {
        jobModal.style.display = 'none';
    }, 300); 
  }

  function openAddRankModal(jobName) {
    const addrank = document.getElementById("addrank-modal");
    const closeaddrankmodal = document.getElementById("closeAddRankModal");
    const selectedJobName = document.getElementById("selectedJobName");

    if (!jobName) {
        return;
    }

    document.getElementById("gradeInput").value = "";
    document.getElementById("nameInput").value = "";
    document.getElementById("labelInput").value = "";
    document.getElementById("salaryInput").value = "";

    selectedJobName.textContent = jobName;
    addrank.style.display = "flex";
    requestAnimationFrame(() => {
        addrank.style.opacity = 0;
        addrank.style.transform = "scale(0.8)";

        setTimeout(() => {
            addrank.style.transition = "opacity 0.3s ease, transform 0.3s ease";
            addrank.style.opacity = 1;
            addrank.style.transform = "scale(1)";
           closeaddrankmodal.style.display = "flex"; 
        }, 10);
    });
}

document.getElementById("addrank").addEventListener("click", function () {
    let jobName = this.dataset.jobName;  
    if (!jobName) {
        return;
    }
    openAddRankModal(jobName);
});

function addRank() {
    const grade = document.getElementById("gradeInput").value;
    const label = document.getElementById("labelInput").value;
    const salary = document.getElementById("salaryInput").value;
    const selectedJobName = document.getElementById("selectedJobName").textContent; 
    const name = document.getElementById('nameInput').value;

    if (!selectedJobName || !grade || !label || !salary || !name) {
        return;
    }

    const newRank = {
        job_name: selectedJobName,
        name: name,
        grade: parseInt(grade),
        label: label,
        salary: parseInt(salary),
    };

    fetch(`https://d-jobcreator/addJobGrade`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(newRank) 
    }).then(response => response.json())
      .then(data => {
          if (data.status === "ok") {
              const table = document.getElementById("job-ranks-body");
              const newRow = table.insertRow();
              newRow.classList.add("adding");

              newRow.innerHTML = `
                  <td>${newRank.grade}</td>
                  <td>${newRank.label}</td>
                  <td>${newRank.salary}</td>
                  <td>
                      <button class="delete-btn" onclick="deleteRank(this, '${newRank.job_name}', ${newRank.grade})">❌</button>
                  </td>
              `;
              setTimeout(() => {
                  newRow.classList.remove("adding");
              }, 300);

              closeAddRankModal();
          }
      })
      .catch(error => console.error("Error:", error));
}

function closeAddRankModal() {
    const addrank = document.getElementById('addrank-modal');
    addrank.style.opacity = 0;
    addrank.style.transform = 'scale(0.8)';
    setTimeout(() => {
        addrank.style.display = 'none';
    }, 300); 
}
  
  function addJob() {
    const label = document.getElementById("jobLabel").value;
    const name = document.getElementById("jobId").value; 
    const whitelisted = document.getElementById("whitelisted").value;

    if (!label || !name) {
        return;
    }

    const newRank = {
        job_name: name,
        label: label,
        whitelisted: whitelisted
    };

    fetch(`https://d-jobcreator/addJob`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(newRank)
    }) 
    .then(response => response.json())  
    .then(data => {
        closeAddJobModal();
        openAddRankModal(name); 
    })
    .catch(error => {
        console.error("Error adding job:", error);
    });
}


function EditJobModal(jobName) {
    const modal = document.querySelector('.EditJob-modal');
    const modalTitle = document.getElementById('EditJobTitle');

    modalTitle.innerHTML = `Ranks for: ${jobName}`;
    modal.style.display = 'flex';
    modal.style.opacity = 0;
    modal.style.transform = 'scale(0.8)';
    
    setTimeout(() => {
        modal.style.opacity = 1;
        modal.style.transform = 'scale(1)';
    }, 50);

    $.post(`https://${GetParentResourceName()}/getJobGrades`, JSON.stringify({ jobName }), function(resp) {
    });
    document.getElementById("addrank").dataset.jobName = jobName;
    document.getElementById("deletejob").dataset.jobName = jobName;
    document.getElementById("editmarkers").dataset.jobName = jobName;
    document.getElementById("editstashesbutton").dataset.jobName = jobName;
}

function EditJobModalClose() {
    const modal = document.querySelector('.EditJob-modal');
    modal.style.opacity = 0;
    modal.style.transform = 'scale(0.8)';
    setTimeout(() => {
        modal.style.display = 'none';
    }, 400); 
}


document.getElementById("deletejob").addEventListener("click", function () {
    let jobName = this.dataset.jobName;  
    if (!jobName) {
        return;
    }
    deleteJob(jobName);
    const container = document.querySelector('.EditJob-modal');
    container.classList.add("loading");

    setTimeout(() => {
        container.classList.remove("loading");
        EditJobModalClose();
    }, 1000);
});

function deleteJob(jobName) {
    const data = {
        job_name: jobName,
    };
    setTimeout(() => {
        fetch("https://d-jobcreator/deleteJob", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(data) 
        })
    }, 500); 
}

function showNotification(type, message, duration) {
        const notification = document.createElement('div');
        notification.className = 'notification ' + type;
        notification.innerText = message;
    
        const jobManager = document.getElementById('job-manager');
        jobManager.appendChild(notification);
    
        let offsetTop = 20;
        const existingNotifications = document.querySelectorAll('.notification');
        existingNotifications.forEach((notif, index) => {
            if (index > 0) {
                offsetTop += notif.offsetHeight + 10;
            }
        });
    
        notification.style.top = offsetTop + 'px';
    
        setTimeout(function() {
            notification.style.animation = 'slideOut 0.5s ease-in-out forwards';
            setTimeout(function() {
                notification.remove();
            }, duration);
        }, duration);
    }
    
    window.addEventListener('message', function(event) {
        if (event.data.action == 'showNotification') {
            showNotification(event.data.type, event.data.message, event.data.duration);
        }
    });

    function openEditGarageModal(garage) {
        document.getElementById("garage-id").value = garage.id;
        document.getElementById("garage-location").value = garage.location;
        document.getElementById("spawn-location").value = garage.spawn_location;
        document.getElementById("garage-name").value = garage.name;
        document.getElementById("garagetype").value = garage.type;
        let selectElement = document.getElementById('garageblip');
        selectElement.value = garage.blip ? "1" : "0";
        const vehicleListContainer = document.getElementById("vehicle-list");
        vehicleListContainer.innerHTML = "";
        if (garage.vehicles) {
            let vehicles;
            try {
                vehicles = JSON.parse(garage.vehicles);
            } catch (error) {
                console.error("Error while trying to parse vehicles list!", error);
                vehicles = [];
            }
            vehicles.forEach(vehicle => {
                let vehicleDiv = document.createElement("div");
                vehicleDiv.classList.add("vehicle-item");
                vehicleDiv.textContent = vehicle;

                let deleteButton = document.createElement("button");
                deleteButton.textContent = "X";
                deleteButton.classList.add("delete-btn");
                deleteButton.addEventListener("click", function() {
                    vehicleDiv.remove(); 
                });
                vehicleDiv.appendChild(deleteButton);
                vehicleListContainer.appendChild(vehicleDiv);
            });
        }
    
        const editGarageModal = document.getElementById('edit-garage-modal');
        editGarageModal.style.display = "flex";
        editGarageModal.style.opacity = 0;
        editGarageModal.style.transform = "scale(0.9)";
        editGarageModal.style.transition = "opacity 0.2s ease-in-out, transform 0.2s ease-in-out";
    
        setTimeout(() => {
            editGarageModal.style.opacity = 1;
            editGarageModal.style.transform = "scale(1)";
        }, 50);
    }
    


    document.getElementById("close-garage-modal").addEventListener("click", function () {
        const editGarageModal = document.getElementById('edit-garage-modal');
        editGarageModal.style.opacity = 0;
        editGarageModal.style.transform = "scale(0.9)";

        setTimeout(() => {
            editGarageModal.style.display = "none";
        }, 200);
    });
    window.addEventListener("message", function(event) {
        if (event.data.type === "loadGarages") {
            loadGarages(event.data.garages);
        }
    });

    function validateVector3(input) {
        const regex = /^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$/;
        return regex.test(input.trim());
    }

    function saveGarageChanges() {
        const garageId = document.getElementById("garage-id").value.trim();

        if (!garageId) {
            return;
        }
        const job = document.getElementById("allmarkers-title").dataset.jobName;
        const garageLocation = document.getElementById("garage-location").value.trim();
        const spawnLocation = document.getElementById("spawn-location").value.trim();
        const garageName = document.getElementById("garage-name").value.trim();
        const garageType = document.getElementById("garagetype").value.trim();
        const garageBlip = Number(document.getElementById("garageblip").value.trim());
        const vehicleListContainer = document.getElementById("vehicle-list");
        const vehicleDivs = vehicleListContainer.getElementsByClassName("vehicle-item");
        const vehicles = Array.from(vehicleDivs).map(div => div.textContent);

        if (!validateVector3(garageLocation) || !validateVector3(spawnLocation)) {
            return;
        }
    
        const updatedGarageData = {
            job: job,
            id: parseInt(garageId),
            name: garageName,
            location: garageLocation.split(",").map(Number).join(","),
            spawn_location: spawnLocation.split(",").map(Number).join(","),            
            vehicles: JSON.stringify(vehicles),
            type: garageType,
            blip: garageBlip
        };
        fetch("https://d-jobcreator/updateGarage", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(updatedGarageData)
        }).then(response => response.json())
          .then(data => {
              if (data.success) {
                  closeAddGarageForm();
              } else {
              }
          }).catch(error => console.error("ERROR:", error));
    }

    
window.addEventListener('message', function(event) {
    if (event.data.type === 'receiveUpdatedGarage') {
        const updatedGarage = event.data.garage;
    }
});

document.getElementById("editmarkers").addEventListener("click", function () {
    let jobName = this.dataset.jobName;  
    if (!jobName) {
        return;
    }
    openEditMarkers(jobName)
});


function openEditMarkers(jobName) {
    const markersContainer = document.getElementById('allmarkers');
    const header = document.getElementById('allmarkers-title');

    if (!jobName) {
        return;
    }
    header.dataset.jobName = jobName;
    header.textContent = `Manage garages for: ${jobName}`;

    markersContainer.style.display = "flex";
    requestAnimationFrame(() => {
        markersContainer.style.opacity = 0;
        markersContainer.style.transform = "scale(0.8)";

        setTimeout(() => {
            markersContainer.style.transition = "opacity 0.3s ease, transform 0.3s ease";
            markersContainer.style.opacity = 1;
            markersContainer.style.transform = "scale(1)";
        }, 10);
    });
    fetchGarages();
}

function loadGarages(garages) {
    console.log("Loading garages...", garages);

    if (!Array.isArray(garages)) { 
        console.log("Garages type:", typeof garages);
        return;
    }

    const garagesList = document.getElementById("job-garages-list");
    if (!garagesList) {
        return;
    }

    const garageIcons = {
        car: "🚗",
        helicopter: "🚁",
        boat: "🚤"
    };
    
    garagesList.innerHTML = "";
    garages.forEach(garage => {
        const garageDiv = document.createElement("div");
        garageDiv.classList.add("garage-item");

        garageDiv.innerHTML = `
            <div class="garage-icon">${garageIcons[garage.type] || "❓"}</div>
            <div class="garage-info">
                <strong>Name: ${garage.name}</strong> - Garage id - ${garage.id}    
            </div>
              <button class="bin-button" onclick="deleteGarage('${garage.id}', this)">
  <svg
    class="bin-top"
    viewBox="0 0 39 7"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <line y1="5" x2="39" y2="5" stroke="white" stroke-width="4"></line>
    <line
      x1="12"
      y1="1.5"
      x2="26.0357"
      y2="1.5"
      stroke="white"
      stroke-width="3"
    ></line>
  </svg>
  <svg
    class="bin-bottom"
    viewBox="0 0 33 39"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <mask id="path-1-inside-1_8_19" fill="white">
      <path
        d="M0 0H33V35C33 37.2091 31.2091 39 29 39H4C1.79086 39 0 37.2091 0 35V0Z"
      ></path>
    </mask>
    <path
      d="M0 0H33H0ZM37 35C37 39.4183 33.4183 43 29 43H4C-0.418278 43 -4 39.4183 -4 35H4H29H37ZM4 43C-0.418278 43 -4 39.4183 -4 35V0H4V35V43ZM37 0V35C37 39.4183 33.4183 43 29 43V35V0H37Z"
      fill="white"
      mask="url(#path-1-inside-1_8_19)"
    ></path>
    <path d="M12 6L12 29" stroke="white" stroke-width="4"></path>
    <path d="M21 6V29" stroke="white" stroke-width="4"></path>
  </svg>
</button>
            <button class="edit-garage-btn">✏️ Edit</button>
        `;

        garageDiv.querySelector(".edit-garage-btn").addEventListener("click", function () {
            openEditGarageModal(garage);
        });

        garagesList.appendChild(garageDiv);
    });
}


function fetchGarages() {
    const jobName = document.getElementById("allmarkers-title").dataset.jobName;
    fetch(`https://d-jobcreator/getGaragesForJob`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ jobName }) 
    })
    .then(response => response.json())
    .then(data => {
        loadGarages(data.garages);
    })
    .catch(error => console.error("Error trying to load garages:", error));
}


function closeEditmarkers() {
    const markersContainer = document.getElementById('allmarkers');
    markersContainer.style.opacity = 0;
    markersContainer.style.transform = 'scale(0.8)';
    setTimeout(() => {
        markersContainer.style.display = 'none';
    }, 300); 
}



document.getElementById('addgarage').addEventListener('click', function() {
    openAddGarageForm();
});



function openAddGarageForm() {
    const addGarageContainer = document.getElementById("addGarageContainer");
    addGarageContainer.style.display = 'flex';
    addGarageContainer.style.opacity = 1;
    addGarageContainer.style.transform = 'scale(0.8)';
    setTimeout(() => {
        addGarageContainer.style.opacity = 1;
        addGarageContainer.style.transform = 'scale(1)';
    }, 50);
  }

function closeAddGarageForm() {
    const addGarageContainer = document.getElementById("addGarageContainer");
    addGarageContainer.style.opacity = 0;
    addGarageContainer.style.transform = 'scale(0.8)';
    setTimeout(() => {
        addGarageContainer.style.display = 'none';
    }, 300); 
  }


function parseVector3(input) {
    if (!input) return null;
    const parts = input.split(",").map(str => parseFloat(str.trim()));
    if (parts.length === 3 && parts.every(num => !isNaN(num))) {
        return { x: parts[0], y: parts[1], z: parts[2] };
    } else {
        return null;
    }
}

function addNewGarage() {
    const job = document.getElementById("allmarkers-title")?.dataset?.jobName || null;
    const name = document.getElementById("newgaragename")?.value.trim() || null;
    const garageLocation = document.getElementById("garagelocation").value.trim();
    const spawnLocation = document.getElementById("spawnLocation").value.trim();
    const type = document.getElementById("garagetype")?.value.trim() || null;
    const blip = document.getElementById("garageblip")?.value.trim() || null;
    
    const vehicleDivs = document.querySelectorAll("#vehicle-list .vehicle-item");
    const vehicles = Array.from(vehicleDivs).map(div => div.textContent); 

    function validateVector3(input) {
        const regex = /^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$/;
        return regex.test(input.trim());
    }

    if (!job || !name || !vehicles || !type) {
        return;
    }

    if (!validateVector3(garageLocation) || !validateVector3(spawnLocation)) {
        return;
    }

    const addGarageData = {
        job,
        name,
        location: garageLocation.split(",").map(Number).join(","),
        spawn_location: spawnLocation.split(",").map(Number).join(","),        
        vehicles,
        type,
        blip
    };
    

    fetch(`https://d-jobcreator/addNewGarage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(addGarageData),
    })
    .then(response => response.json())
    .then(addGarageData => {
    })
    .catch(error => console.error("❌ERROR: While adding garages:", error));
}


function deleteGarage(garageId) {
    const job = document.getElementById("allmarkers-title").dataset.jobName;
    const data = {
        id: garageId,
        job: job
    };
    setTimeout(() => {
        fetch("https://d-jobcreator/deleteGarage", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(data) 
        })
    }, 500); 
}

document.getElementById('editvehicles').addEventListener('click', function() {
    openEditVehiclesModal();
})

document.getElementById('addnewgarageeditvehicles').addEventListener('click', function() {
    openEditVehiclesModal();
})

function openEditVehiclesModal() {
    const editvehiclesmodal = document.getElementById("editvehiclesmodal");
    editvehiclesmodal.style.display = 'flex';
    editvehiclesmodal.style.opacity = 1;
    editvehiclesmodal.style.transform = 'scale(0.8)';
    setTimeout(() => {
        editvehiclesmodal.style.opacity = 1;
        editvehiclesmodal.style.transform = 'scale(1)';
    }, 50);
  }

  function closeEditVehiclesModal() {
    const editvehiclesmodal = document.getElementById('editvehiclesmodal');
    editvehiclesmodal.style.opacity = 0;
    editvehiclesmodal.style.transform = 'scale(0.8)';
    setTimeout(() => {
        editvehiclesmodal.style.display = 'none';
    }, 300); 
}

document.getElementById("addnewvehicle").addEventListener("keypress", function(event) {
    if (event.key === "Enter") {
        addVehicle();
    }
});

function addVehicle() {
    let input = document.getElementById("addnewvehicle");
    let vehicleName = input.value.trim();

    if (vehicleName !== "") {
        let newDiv = document.createElement("div");
        newDiv.classList.add("vehicle-item");
        newDiv.textContent = vehicleName;
        document.getElementById("vehicle-list").appendChild(newDiv);
        input.value = ""; 
    }
}

function openEditStashes() {
    const jobName = document.getElementById("editstashesbutton").dataset.jobName;
    const editstashes = document.getElementById("editstashes");
    editstashes.style.display = 'flex';
    editstashes.style.opacity = 1;
    editstashes.style.transform = 'scale(0.8)';
    setTimeout(() => {
        editstashes.style.opacity = 1;
        editstashes.style.transform = 'scale(1)';
    }, 50);
    fetch(`https://d-jobcreator/getStashLocation`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ jobName }) 
    }).then(response => response.json())
      .then(data => {
          if (data.stashLocation) {
              const stashLocation = `${data.stashLocation.x}, ${data.stashLocation.y}, ${data.stashLocation.z}`;
              document.getElementById("stashlocation").value = stashLocation;
              document.getElementById("stashCapacity").value = stashCapacity;
              document.getElementById("stashCapacity").value = stashSlots;

          } else {
              
          }
      })
      .catch(error => {
          console.error("Error fetching stash location:", error); 
      });
}

function closeEditStashes() {
    const editstashes = document.getElementById("editstashes");
    editstashes.style.opacity = 0;
    editstashes.style.transform = 'scale(0.8)';
    setTimeout(() => {
        editstashes.style.display = 'none';
    }, 300); 
}

document.getElementById('editstashesbutton').addEventListener('click', function() {
    openEditStashes();
});

window.addEventListener("message", function(event) {
    if (event.data.action === "setStashLocation") {
        const stashLocation = event.data.location;
        const stashCapacity = event.data.capacity;
        const stashSlots = event.data.slots;
        if (stashLocation) {
            document.getElementById("stashlocation").value = `${stashLocation.x}, ${stashLocation.y}, ${stashLocation.z}`;
            document.getElementById("stashCapacity").value = stashCapacity;
            document.getElementById("stashSlots").value = stashSlots;   
        }
    }
});



function saveStashLocation() {
    const jobName = document.getElementById("editstashesbutton").dataset.jobName;
    const stashLocationInput = document.getElementById("stashlocation").value;
    const stashCapacity = document.getElementById("stashCapacity").value;
    const stashSlots = document.getElementById("stashSlots").value;
    const stashLocationArray = stashLocationInput.split(',').map(Number);

    if (stashLocationArray.length !== 3 || stashLocationArray.some(isNaN)) {
        return;
    }
    const updatedStashData = {
        jobName: jobName,
        stashCapacity: stashCapacity,
        stashSlots: stashSlots,
        stashLocation: {
            x: stashLocationArray[0],
            y: stashLocationArray[1],
            z: stashLocationArray[2]
        }
    };

    fetch("https://d-jobcreator/updateStash", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(updatedStashData)
    }).then(response => response.json())
      .then(data => {
          if (data.success) {
              closeAddGarageForm();
          } else {
          }
      }).catch(error => console.error("ERROR:", error));
}

document.getElementById('saveStashButton').addEventListener('click', saveStashLocation);

function searchJob() {
    const input = document.getElementById("searchInput");
    const filter = input.value.toLowerCase();
    const jobsList = document.getElementById("jobsList");
    const jobItems = jobsList.getElementsByClassName("job-item");
  
    for (let i = 0; i < jobItems.length; i++) {
      const jobText = jobItems[i].textContent || jobItems[i].innerText;
      
      if (jobText.toLowerCase().indexOf(filter) > -1) {
        jobItems[i].style.display = "";
      } else {
        jobItems[i].style.display = "none";
      }
    }
  }
  