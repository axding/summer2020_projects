//calculate tip
function calculate() {
  const bill = document.getElementById("billAmt").value;
  const service = document.getElementById("tip").value;
  const people = document.getElementById("peopleamt").value;

  if (service == 0 || bill == "" || people == "") {
    alert("Please fill in all blanks");
    return;
  }

  if (people == 1) {
    document.getElementById("each").style.display = "none";
  }
  else {
    document.getElementById("each").style.display = "block";
  }

  let val = (bill * service) / people;
  val = Math.round(val * 100) / 100;
  val = val.toFixed(2);

  document.getElementById("totalTip").style.display = "block";
  document.getElementById("amount").innerHTML = val;
}

document.getElementById("totalTip").style.display = "none";

document.getElementById("calculate").onclick = function() {
  calculate();
}
