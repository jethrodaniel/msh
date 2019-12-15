import React, { Component } from 'react';

const e = React.createElement;

export class Rotating extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      pos: 0,
      direction: 'clockwise'
    };
  }

  next() {
    if (this.state.pos > 4)
      this.setState({
        pos: this.state.pos - 1,
        direction: 'counter-clockwise'
      });
    else if (this.state.pos < -4)
      this.setState({
        pos: this.state.pos + 1,
        direction: 'clockwise'
      });
    else
      if (this.state.direction == 'clockwise')
        this.setState({pos: this.state.pos + 1});
      else
        this.setState({pos: this.state.pos - 1});
  }

  componentDidMount() {
    this.timerID = setInterval(() => this.next(), 50);
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }

  render() {
    let style = {
      rotate: `${this.state.pos * 0.2}deg`
    }
    return e('div', {style: style},
      this.props.content
    );
  }
}
