import yargs from 'yargs/yargs';

import { hideBin } from 'yargs/helpers';
import { ConfigureEvents, HolographERC20Event, HolographERC721Event } from './utils/events';

interface EventNameToEnumValueMap {
  [key: string]: HolographERC20Event | HolographERC721Event;
}

const eventNameToEnumValue: EventNameToEnumValueMap = {
  // HolographERC20Event mappings
  'HolographERC20Event.bridgeIn': HolographERC20Event.bridgeIn,
  'HolographERC20Event.bridgeOut': HolographERC20Event.bridgeOut,
  'HolographERC20Event.afterApprove': HolographERC20Event.afterApprove,
  'HolographERC20Event.beforeApprove': HolographERC20Event.beforeApprove,
  'HolographERC20Event.afterOnERC20Received': HolographERC20Event.afterOnERC20Received,
  'HolographERC20Event.beforeOnERC20Received': HolographERC20Event.beforeOnERC20Received,
  'HolographERC20Event.afterBurn': HolographERC20Event.afterBurn,
  'HolographERC20Event.beforeBurn': HolographERC20Event.beforeBurn,
  'HolographERC20Event.afterMint': HolographERC20Event.afterMint,
  'HolographERC20Event.beforeMint': HolographERC20Event.beforeMint,
  'HolographERC20Event.afterSafeTransfer': HolographERC20Event.afterSafeTransfer,
  'HolographERC20Event.beforeSafeTransfer': HolographERC20Event.beforeSafeTransfer,
  'HolographERC20Event.afterTransfer': HolographERC20Event.afterTransfer,
  'HolographERC20Event.beforeTransfer': HolographERC20Event.beforeTransfer,
  'HolographERC20Event.onAllowance': HolographERC20Event.onAllowance,

  // HolographERC721Event mappings
  'HolographERC721Event.bridgeIn': HolographERC721Event.bridgeIn,
  'HolographERC721Event.bridgeOut': HolographERC721Event.bridgeOut,
  'HolographERC721Event.afterApprove': HolographERC721Event.afterApprove,
  'HolographERC721Event.beforeApprove': HolographERC721Event.beforeApprove,
  'HolographERC721Event.afterApprovalAll': HolographERC721Event.afterApprovalAll,
  'HolographERC721Event.beforeApprovalAll': HolographERC721Event.beforeApprovalAll,
  'HolographERC721Event.afterBurn': HolographERC721Event.afterBurn,
  'HolographERC721Event.beforeBurn': HolographERC721Event.beforeBurn,
  'HolographERC721Event.afterMint': HolographERC721Event.afterMint,
  'HolographERC721Event.beforeMint': HolographERC721Event.beforeMint,
  'HolographERC721Event.afterSafeTransfer': HolographERC721Event.afterSafeTransfer,
  'HolographERC721Event.beforeSafeTransfer': HolographERC721Event.beforeSafeTransfer,
  'HolographERC721Event.afterTransfer': HolographERC721Event.afterTransfer,
  'HolographERC721Event.beforeTransfer': HolographERC721Event.beforeTransfer,
  'HolographERC721Event.beforeOnERC721Received': HolographERC721Event.beforeOnERC721Received,
  'HolographERC721Event.afterOnERC721Received': HolographERC721Event.afterOnERC721Received,
  'HolographERC721Event.onIsApprovedForAll': HolographERC721Event.onIsApprovedForAll,
  'HolographERC721Event.customContractURI': HolographERC721Event.customContractURI,
};

/**
 * Generates the configuration for the specified events as 32 bytes hex string.
 * Example usage:
 *
 * npx ts-node scripts/configure-events.ts --events HolographERC721Event.beforeSafeTransfer HolographERC721Event.beforeTransfer HolographERC721Event.onIsApprovedForAll HolographERC721Event.customContractURI
 *
 */
async function main() {
  const argv = yargs(hideBin(process.argv))
    .option('events', {
      type: 'array',
      describe: 'List of events to configure',
      demandOption: true,
    })
    .coerce('events', (arg: string[]) => {
      return arg.map((event: string) => {
        const enumValue = eventNameToEnumValue[event];
        if (typeof enumValue === 'undefined') {
          throw new Error(`Event name "${event}" is not recognized.`);
        }
        return enumValue;
      });
    })
    .parseSync();

  const events = argv.events as (HolographERC20Event | HolographERC721Event)[];

  if (!events || events.length === 0) {
    console.error('No events specified. Use the --events flag to specify events.');
    process.exit(1);
  }

  const eventConfigHex = ConfigureEvents(events as any);
  console.log('Events configured:', eventConfigHex);

  for (const eventEnumValue of events) {
    const eventName = getEventNameByValue(eventEnumValue, true); // Assuming true for HolographERC721Event
    const isRegistered = isEventRegistered(eventConfigHex, eventEnumValue);
    if (eventName) {
      console.log(`${eventName} is ${isRegistered ? 'registered' : 'not registered'}.`);
    } else {
      console.log(`Event with enum value ${eventEnumValue} is not recognized.`);
    }
  }

  console.log('Events configured successfully.');
}

// Define a reverse lookup function for event enum values to names
function getEventNameByValue(eventValue: number, isERC721: boolean): string | undefined {
  for (const [key, value] of Object.entries(eventNameToEnumValue)) {
    if (value === eventValue && key.startsWith(isERC721 ? 'HolographERC721Event' : 'HolographERC20Event')) {
      return key;
    }
  }
  return undefined;
}

/**
 * Checks if an event is registered in the event configuration.
 * @param eventConfigHex The event configuration in hexadecimal string format.
 * @param eventName The event name as a value from the HolographERC721Event enum.
 * @returns {boolean} True if the event is registered; otherwise, false.
 */
function isEventRegistered(eventConfigHex: string, eventName: HolographERC721Event | HolographERC20Event): boolean {
  const eventConfig: bigint = BigInt(eventConfigHex);
  // No need to subtract 1 if your enums are zero-based
  return ((eventConfig >> BigInt(eventName)) & BigInt(1)) === BigInt(1);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
