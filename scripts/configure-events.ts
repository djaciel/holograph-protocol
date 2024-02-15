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

  const configuredEvents = ConfigureEvents(events as any);
  console.log('Events configured:', configuredEvents);
  console.log('Events configured successfully.');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
