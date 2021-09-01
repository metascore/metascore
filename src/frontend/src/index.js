import { backend } from "../../declarations/backend";

setInterval(() => {
  backend.canister_heartbeat();
}, 5 * 1000);