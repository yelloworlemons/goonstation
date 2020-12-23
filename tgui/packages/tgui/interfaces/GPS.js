/**
 * Copyright (c) 2020 @ZeWaka
 * SPDX-License-Identifier: ISC
 */

import { useBackend } from '../backend';
import { Box, Button, NoticeBox, Divider, BlockQuote, Icon, Flex } from '../components';
import { Window } from '../layouts';

export const SlotMachine = (props, context) => {
  const { data } = useBackend(context);
  const { serial, identifier, broadcasting, distress } = data;
  return (
    <Window
      title="GPS"
      width={375}
      height={190}>
      <Window.Content>
        <BlockQuote>
          Each GPS is coined with a unique four digit number followed by a four letter identifier.
          <br />
          This GPS is assigned <strong>{ serial }-{ identifier }</strong>.
        </BlockQuote>
        <Flex>
          <Flex.Item>
            <Button
            icon="satellite-dish"
            selected={ broadcasting }
            content='Toggle Broadcasting'
            onClick={() => act('toggle_broadcasting')} />
          </Flex.Item>
          <Flex.Item>
            <Button
            icon="fingerprint"
            content='Change Identifier'
            onClick={() => act('set_ident')} />
          </Flex.Item>
          <Flex.Item>
            <Button
            icon="exclamation-triangle"
            color={ distress ? 'red' : 'default' }
            content='Toggle Distress Signal'
            onClick={() => act('toggle_distress')} />
          </Flex.Item>
        </Flex>
        <Divider />
        <GPSUnits />
        <TrackingImplants />
        <Beacons />
      </Window.Content>
    </Window>
  );
};
