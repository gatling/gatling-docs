//#injection-from-options
import { getParameter } from "@gatling.io/core";

const nbUsers = parseInt(getParameter(
  "users", // Key used to identify the option
  "1" // Default value (optional)
));
const myRamp = parseInt(getParameter("ramp", "0"));

setUp(scn.injectOpen(rampUsers(nbUsers).during(myRamp)));
//#injection-from-options

//#injection-from-env-vars
import { getEnvironmentVariable } from "@gatling.io/core";

const mySecret = getEnvironmentVariable(
  "MY_SECRET", // Name of the environment variables
  "FOO"// Default value (optional)
);
//#injection-from-env-vars
