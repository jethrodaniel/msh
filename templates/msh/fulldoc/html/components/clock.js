import React, { Component } from 'react';

import moment from 'moment';

const e = React.createElement;

export class Clock extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      time: moment(),
      time_format: props.time,
      date_format: props.date
    };
  }

  formattedTime() {
    return this.state.time.format(this.state.time_format);
  }

  formattedDate() {
    return this.state.time.format(this.state.date_format);
  }

  componentDidMount() {
    this.timerID = setInterval(() => this.tick(), 5000);
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }

  tick() {
    this.setState({
      time: moment()
    });
  }

  render() {
    return e('div', {className: 'clock'}, [
      e('div', {className: 'clock-time'}, this.formattedTime()),
      e('div', {className: 'clock-date'}, this.formattedDate())
    ]);
  }
};
